FROM node:22-slim AS builder

WORKDIR /app
RUN apt-get update && apt-get upgrade -y && rm -rf /var/lib/apt/lists/*
COPY package.json ./
RUN npm install

FROM node:22-slim

RUN apt-get update && apt-get upgrade -y && rm -rf /var/lib/apt/lists/*
USER node
WORKDIR /home/node/app

COPY --chown=node:node --from=builder /app/node_modules ./node_modules
COPY --chown=node:node . .

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost:3000/health || exit 1

EXPOSE 3000

CMD ["node", "app.js"]
