# Build stage - install dependencies
FROM python:3.12-alpine AS builder

WORKDIR /app

# Install build dependencies for compiled packages
RUN apk add --no-cache gcc musl-dev libffi-dev

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt

# Production stage - minimal runtime (<180MB)
FROM python:3.12-alpine

LABEL org.opencontainers.image.title="CloudShop Products API"
LABEL org.opencontainers.image.description="Products microservice for CloudShop"

# Install runtime dependencies only
RUN apk add --no-cache libffi && \
    addgroup -g 1001 -S python && \
    adduser -u 1001 -S python -G python

WORKDIR /app

# Copy installed packages from builder
COPY --from=builder /root/.local /home/python/.local

# Set PATH to include user packages
ENV PATH="/home/python/.local/bin:$PATH"

# Copy application code
COPY --chown=python:python . .

# Remove unnecessary files
RUN rm -rf .git .gitignore *.md Dockerfile .dockerignore __pycache__ 2>/dev/null || true && \
    chown -R python:python /home/python/.local

# Use non-root user
USER python

# Expose port
EXPOSE 8082

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8082/health || exit 1

# Start the application
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8082"]
