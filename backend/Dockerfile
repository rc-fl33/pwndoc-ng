FROM node:20-alpine AS builder

RUN mkdir -p /app
WORKDIR /app
COPY package*.json ./
RUN apk --no-cache add --virtual builds-deps build-base python3 git
RUN npm ci --omit=dev

FROM node:20-alpine

RUN addgroup -S appgroup && adduser -S appuser -G appgroup
RUN mkdir -p /app && chown appuser:appgroup /app
WORKDIR /app

COPY --from=builder /app/node_modules ./node_modules
COPY . .

RUN chown -R appuser:appgroup /app

USER appuser
EXPOSE 4242
ENV NODE_ENV=prod
ENV NODE_ICU_DATA=node_modules/full-icu

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD node -e "const http = require('https'); const options = {hostname:'localhost',port:4242,path:'/api/health',rejectUnauthorized:false}; http.get(options, (r) => { process.exit(r.statusCode === 200 ? 0 : 1); }).on('error', () => process.exit(1));"

ENTRYPOINT ["node", "src/app.js"]
