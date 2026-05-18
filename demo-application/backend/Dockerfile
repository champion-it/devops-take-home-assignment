# syntax=docker/dockerfile:1.7

# ---------- Stage 1: dependencies (with dev deps for testing) ----------
FROM node:20-alpine AS deps
WORKDIR /app
COPY package.json package-lock.json* ./
RUN --mount=type=cache,target=/root/.npm \
    npm ci --include=dev

# ---------- Stage 2: test ----------
FROM deps AS test
COPY . .
RUN npm test

# ---------- Stage 3: prod dependencies (slim) ----------
FROM node:20-alpine AS prod-deps
WORKDIR /app
COPY package.json package-lock.json* ./
RUN --mount=type=cache,target=/root/.npm \
    npm ci --omit=dev && npm cache clean --force

# ---------- Stage 4: runtime ----------
FROM node:20-alpine AS runtime
WORKDIR /app

# Add tini for proper signal handling + curl for healthcheck
RUN apk add --no-cache tini curl \
 && addgroup -S app && adduser -S app -G app

ENV NODE_ENV=production \
    PORT=8080 \
    LOG_LEVEL=info

COPY --from=prod-deps --chown=app:app /app/node_modules ./node_modules
COPY --chown=app:app src ./src
COPY --chown=app:app package.json ./

USER app
EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD curl -fsS http://127.0.0.1:8080/healthz || exit 1

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["node", "src/server.js"]
