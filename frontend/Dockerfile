# Build stage
FROM node:20-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies (dev needed for build)
RUN npm install --omit=dev && npm install vite @vitejs/plugin-react

# Copy source code
COPY . .

# Build the application
RUN npm run build

# Production stage - minimal nginx (<50MB)
FROM nginx:1.27-alpine3.21

LABEL org.opencontainers.image.title="CloudShop Frontend"
LABEL org.opencontainers.image.description="Frontend for CloudShop e-commerce"

# Upgrade all packages to fix CVEs and remove default content
RUN apk upgrade --no-cache && rm -rf /usr/share/nginx/html/*

# Copy custom nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy built assets from builder stage
COPY --from=builder /app/dist /usr/share/nginx/html

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3000/health || exit 1

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
