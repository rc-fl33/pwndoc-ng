### STAGE 1: Build ###
FROM node:20-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

### STAGE 2: Run ###
FROM nginx:stable-alpine
COPY .docker/nginx.conf /etc/nginx/conf.d/default.conf
RUN mkdir -p /etc/nginx/ssl
COPY ssl/server* /etc/nginx/ssl/
COPY --from=build /app/dist/spa /usr/share/nginx/html

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD wget --no-check-certificate -q -O /dev/null https://localhost:8443/ || exit 1

EXPOSE 8443
CMD ["nginx", "-g", "daemon off;"]
