# syntax=docker/dockerfile:1.7

# ---------- Stage 1: build ----------
FROM node:20-alpine AS builder
WORKDIR /app

COPY package.json package-lock.json* ./
RUN --mount=type=cache,target=/root/.npm \
    npm ci

COPY . .
RUN npm run build

# ---------- Stage 2: runtime (nginx) ----------
FROM nginxinc/nginx-unprivileged:1.27-alpine AS runtime

USER root
RUN apk add --no-cache curl
USER nginx

ENV BACKEND_HOST=backend \
    BACKEND_PORT=8080

COPY --from=builder /app/dist /usr/share/nginx/html
# The nginx-unprivileged image runs envsubst on /etc/nginx/templates/*.template at boot,
# rendering each file to /etc/nginx/conf.d/<name> (with the .template suffix stripped).
COPY nginx.conf /etc/nginx/templates/default.conf.template

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -fsS http://127.0.0.1:8080/healthz || exit 1

CMD ["nginx", "-g", "daemon off;"]
