FROM node:22-slim AS builder
WORKDIR /app
# hadolint ignore=DL3008,DL3009
RUN apt-get update && apt-get upgrade -y --no-install-recommends && rm -rf /var/lib/apt/lists/*
COPY package.json ./
RUN npm install

FROM node:22-slim
# hadolint ignore=DL3008,DL3009
RUN apt-get update && apt-get upgrade -y --no-install-recommends && rm -rf /var/lib/apt/lists/*
USER node
WORKDIR /home/node/app
COPY --chown=node:node --from=builder /app/node_modules ./node_modules
COPY --chown=node:node . .
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD node -e "const http = require('http'); http.get('http://localhost:3000/health', (r) => { process.exit(r.statusCode === 200 ? 0 : 1); }).on('error', () => { process.exit(1); })"
EXPOSE 3000
CMD ["node", "app.js"]
