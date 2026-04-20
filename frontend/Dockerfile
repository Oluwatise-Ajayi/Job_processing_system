FROM node:20-alpine AS builder

WORKDIR /app
COPY package.json ./
RUN npm install

FROM node:20-alpine

USER node
WORKDIR /home/node/app

COPY --chown=node:node --from=builder /app/node_modules ./node_modules
COPY --chown=node:node . .

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost:3000/health || exit 1

EXPOSE 3000

CMD ["node", "app.js"]
