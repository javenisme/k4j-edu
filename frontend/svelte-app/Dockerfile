# Build stage
FROM node:20-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies (no package-lock.json committed, so use install not ci)
RUN npm install

# Copy source code
COPY . .

# Build the application (skip version generation in CI)
RUN node scripts/generate-version.js 2>/dev/null || true && npm run build

# Production stage - Nginx static server with envsubst
FROM nginx:alpine

# Install envsubst (gettext) for runtime config
RUN apk add --no-cache gettext

# Copy built files from builder.
# svelte.config.js (adapter-static) outputs to ../build, i.e. /build in the container.
COPY --from=builder /build /usr/share/nginx/html

# Copy config template
COPY --from=builder /app/static/config.js /usr/share/nginx/html/config.js.template

# Create nginx config for SPA routing.
# The templates dir does not exist in nginx:alpine by default; create it.
# Use ${PORT} (not ${PORT:-80}) — envsubst does not support the :-default syntax.
RUN mkdir -p /etc/nginx/templates && printf 'server {\n\
    listen ${PORT};\n\
    server_name _;\n\
    root /usr/share/nginx/html;\n\
    index index.html;\n\
    location / {\n\
        try_files $uri $uri/ /index.html;\n\
    }\n\
}\n' > /etc/nginx/templates/default.conf.template

# Entrypoint: substitute env vars in config.js, then start nginx
CMD ["sh", "-c", "envsubst < /usr/share/nginx/html/config.js.template > /usr/share/nginx/html/config.js && nginx -g 'daemon off;'"]

EXPOSE 80
