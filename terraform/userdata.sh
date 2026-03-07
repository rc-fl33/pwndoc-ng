#!/bin/bash
set -euo pipefail

# Log all output
exec > >(tee /var/log/pwndoc-setup.log) 2>&1
echo "=== PwnDoc-NG Setup Started $(date) ==="

# --- Install Docker ---
dnf update -y
dnf install -y docker git

systemctl enable docker
systemctl start docker

# Install Docker Compose v2 plugin
mkdir -p /usr/local/lib/docker/cli-plugins
COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep '"tag_name"' | cut -d'"' -f4)
curl -SL "https://github.com/docker/compose/releases/download/$${COMPOSE_VERSION}/docker-compose-linux-x86_64" -o /usr/local/lib/docker/cli-plugins/docker-compose
chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

# --- Mount EBS volume for MongoDB data ---
EBS_DEVICE="${ebs_device}"
MOUNT_POINT="/mnt/mongo-data"

# Wait for device to appear
for i in $(seq 1 30); do
  if [ -b "$EBS_DEVICE" ] || [ -b "/dev/nvme1n1" ]; then
    break
  fi
  sleep 2
done

# NVMe devices may appear as /dev/nvme1n1
if [ -b "/dev/nvme1n1" ]; then
  EBS_DEVICE="/dev/nvme1n1"
fi

# Format only if no filesystem exists
if ! blkid "$EBS_DEVICE"; then
  mkfs.xfs "$EBS_DEVICE"
fi

mkdir -p "$MOUNT_POINT"
mount "$EBS_DEVICE" "$MOUNT_POINT"
echo "$EBS_DEVICE $MOUNT_POINT xfs defaults,nofail 0 2" >> /etc/fstab

# --- Clone and configure application ---
APP_DIR="/opt/pwndoc-ng"
git clone -b "${git_branch}" "${git_repo_url}" "$APP_DIR"
cd "$APP_DIR"

# Create .env file
cat > .env <<'ENVEOF'
NODE_ENV=prod
APP_PORT=4242
COLLAB_WEBSOCKET_PORT=8440
MONGO_HOST=mongo-pwndoc-ng
MONGO_PORT=27017
MONGO_DB_NAME=pwndoc
MONGO_USERNAME=pwndoc
MONGO_PASSWORD=${mongo_app_password}
MONGO_INITDB_ROOT_USERNAME=root
MONGO_INITDB_ROOT_PASSWORD=${mongo_root_password}
JWT_SECRET=${jwt_secret}
JWT_REFRESH_SECRET=${jwt_refresh_secret}
CORS_ORIGIN=*
BODY_LIMIT=20mb
APIDOC=false
ENVEOF

chmod 600 .env

# Override mongo volume to use EBS mount
cat > docker-compose.override.yml <<'OVERRIDE'
version: '3.8'
services:
  mongodb:
    volumes:
      - /mnt/mongo-data:/data/db
OVERRIDE

# --- Generate self-signed SSL certs (replace with ACM/Let's Encrypt for production) ---
mkdir -p backend/ssl frontend/ssl
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout backend/ssl/server.key -out backend/ssl/server.cert \
  -subj "/CN=localhost"
cp backend/ssl/server.key frontend/ssl/server.key
cp backend/ssl/server.cert frontend/ssl/server.cert

# --- Start application ---
docker compose -f docker-compose.prod.yml -f docker-compose.override.yml up -d --build

# --- Create MongoDB application user ---
echo "Waiting for MongoDB to be ready..."
for i in $(seq 1 30); do
  if docker exec mongo-pwndoc-ng mongosh --eval "db.adminCommand('ping')" -u root -p "${mongo_root_password}" --authenticationDatabase admin > /dev/null 2>&1; then
    break
  fi
  sleep 2
done

docker exec mongo-pwndoc-ng mongosh -u root -p "${mongo_root_password}" --authenticationDatabase admin --eval "
  db = db.getSiblingDB('pwndoc');
  db.createUser({
    user: 'pwndoc',
    pwd: '${mongo_app_password}',
    roles: [{ role: 'readWrite', db: 'pwndoc' }]
  });
"

# --- Set up automatic security updates ---
dnf install -y dnf-automatic
systemctl enable --now dnf-automatic-install.timer

# --- Set up log rotation for Docker ---
cat > /etc/docker/daemon.json <<'DAEMON'
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
DAEMON
systemctl restart docker

# Restart containers with new log config
cd "$APP_DIR"
docker compose -f docker-compose.prod.yml -f docker-compose.override.yml up -d

echo "=== PwnDoc-NG Setup Completed $(date) ==="
