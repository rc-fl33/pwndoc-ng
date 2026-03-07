# AWS Optimization Implementation Plan

## Target: EC2 + Docker Compose with Security Hardening + Terraform IaC

---

## Phase 1: Configuration Externalization

### 1.1 Refactor backend config to support environment variables
**Files:** `backend/src/config/config.json`, `backend/src/app.js`, `backend/src/lib/auth.js`

- Modify `app.js` to read DB connection from env vars with config.json as fallback
- Modify `auth.js` to read JWT secrets from env vars (stop writing to config.json)
- Create `backend/src/config/env.js` — centralized env var reader with defaults

### 1.2 Create `.env.example` and docker-compose override
**Files:** `.env.example`, `docker-compose.yml`, `docker-compose.prod.yml`

- Create `.env.example` with all configurable values documented
- Create `docker-compose.prod.yml` — production-ready compose with env var references
- Add `.env` to `.gitignore`

---

## Phase 2: Security Fixes (from SECURITY.md findings)

### 2.1 Fix critical security issues
**SEC-04/05:** Fix CORS — restrict to specific origin (env var configurable)
**SEC-06:** Reduce body-parser limit from 100MB to 20MB
**SEC-11:** Fix nginx TLS — remove TLSv1 and TLSv1.1, add TLSv1.3
**SEC-12:** Fix password validation bug in user route
**SEC-19:** Add rate limiting on login endpoint (express-rate-limit)
**SEC-20/21:** Add security headers in nginx (CSP, HSTS, X-Frame-Options, X-Content-Type-Options)

### 2.2 Add health check endpoint
**File:** `backend/src/app.js`
- Add `GET /api/health` — returns DB connection status
- Add Docker healthcheck to compose files

### 2.3 Add graceful shutdown
**File:** `backend/src/app.js`
- Handle SIGTERM/SIGINT for clean shutdown of Express, Socket.IO, Hocuspocus, and MongoDB connection

---

## Phase 3: Docker Hardening

### 3.1 Update Docker images
- Update `backend/Dockerfile` — use `node:20-alpine` (not pinned patch), add non-root user, multi-stage build
- Update `frontend/Dockerfile` — use `node:20-alpine` for build stage, add non-root nginx user
- Add `.dockerignore` files to both backend and frontend

### 3.2 Production docker-compose
- MongoDB with authentication enabled (MONGO_INITDB_ROOT_USERNAME/PASSWORD)
- Proper restart policies
- Resource limits (mem_limit)
- Health checks for all services
- Remove deprecated `links` directive

---

## Phase 4: Terraform IaC

### 4.1 Core infrastructure
**Directory:** `terraform/`

- `main.tf` — Provider, VPC, subnets, internet gateway
- `ec2.tf` — EC2 instance (t3.small), security groups, key pair
- `storage.tf` — EBS volume for MongoDB data
- `network.tf` — Security groups (SSH, HTTPS only)
- `outputs.tf` — Instance IP, SSH command
- `variables.tf` — Configurable: instance type, region, SSH key, domain
- `userdata.sh` — Cloud-init script: install Docker, clone repo, configure .env, start compose
- `terraform.tfvars.example` — Example variable values

### 4.2 Optional add-ons (in separate tf files)
- `dns.tf` — Route 53 record (if domain provided)
- `backup.tf` — EBS snapshot schedule via DLM
- `monitoring.tf` — CloudWatch agent config, basic alarms

---

## Files to Create/Modify

### New Files
```
.env.example
docker-compose.prod.yml
backend/.dockerignore
frontend/.dockerignore
backend/src/config/env.js
terraform/
  main.tf
  ec2.tf
  storage.tf
  network.tf
  outputs.tf
  variables.tf
  userdata.sh
  terraform.tfvars.example
```

### Modified Files
```
backend/src/app.js              — env vars, health check, graceful shutdown, CORS fix, body limit
backend/src/lib/auth.js         — env var JWT secrets, stop writing to config.json
backend/src/routes/user.js      — rate limiting, password bug fix
backend/Dockerfile              — updated base, non-root user, multi-stage
frontend/Dockerfile             — updated base
frontend/.docker/nginx.conf     — TLS fix, security headers
docker-compose.yml              — healthchecks, mongo auth, resource limits
.gitignore                      — add .env, terraform state files
```

### Dependencies to Add
```
backend: express-rate-limit
```

---

## Estimated Impact
- ~15 files created/modified
- No changes to frontend Vue code or business logic
- Backward compatible — existing docker-compose.yml still works
- New docker-compose.prod.yml for AWS deployment
