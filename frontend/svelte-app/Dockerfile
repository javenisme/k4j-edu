# Build stage
FROM node:20-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci

# Copy source code
COPY . .

# Build the application (skip version generation in CI)
RUN node scripts/generate-version.js 2>/dev/null || true && npm run build

# Production stage - Nginx static server with envsubst
FROM nginx:alpine

# Install envsubst (gettext) for runtime config
RUN apk add --no-cache gettext

# Copy built files from builder
COPY --from=builder /app/build /usr/share/nginx/html

# Copy config template
COPY --from=builder /app/static/config.js /usr/share/nginx/html/config.js.template

# Create nginx config for SPA routing
RUN echo 'server { \
    listen ${PORT:-80}; \
    server_name _; \
    root /usr/share/nginx/html; \
    index index.html; \
    location / { \
        try_files $uri $uri/ /index.html; \
    } \
}' > /etc/nginx/templates/default.conf.template

# Entrypoint: substitute env vars in config.js, then start nginx
CMD ["sh", "-c", "envsubst < /usr/share/nginx/html/config.js.template > /usr/share/nginx/html/config.js && nginx -g 'daemon off;'"]

EXPOSE 80
