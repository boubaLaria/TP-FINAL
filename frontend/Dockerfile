# Build stage
FROM node:20-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies (dev needed for build)
RUN npm install --omit=dev && npm install vite @vitejs/plugin-react

# Copy source code
COPY . .

# Set API URL for build
ARG VITE_API_URL=http://api.local:32286/api
ENV VITE_API_URL=$VITE_API_URL

# Build the application
RUN npm run build

# Production stage - minimal nginx (<50MB)
FROM nginx:1.27-alpine3.21

LABEL org.opencontainers.image.title="CloudShop Frontend"
LABEL org.opencontainers.image.description="Frontend for CloudShop e-commerce"

# Upgrade all packages to fix CVEs and remove default content
RUN apk upgrade --no-cache && rm -rf /usr/share/nginx/html/*

# Create cache directories and set permissions for non-root user
RUN mkdir -p /var/cache/nginx/client_temp \
             /var/cache/nginx/proxy_temp \
             /var/cache/nginx/fastcgi_temp \
             /var/cache/nginx/uwsgi_temp \
             /var/cache/nginx/scgi_temp \
    && chown -R nginx:nginx /var/cache/nginx \
    && chmod -R 755 /var/cache/nginx \
    && chown -R nginx:nginx /etc/nginx/conf.d \
    && touch /var/run/nginx.pid \
    && chown -R nginx:nginx /var/run/nginx.pid

# Copy custom nginx config
COPY nginx.conf /etc/nginx/nginx.conf

# Copy built assets from builder stage
COPY --from=builder /app/dist /usr/share/nginx/html

# Set ownership for nginx user
RUN chown -R nginx:nginx /usr/share/nginx/html

# Switch to non-root user
USER nginx

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3000/health || exit 1

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
