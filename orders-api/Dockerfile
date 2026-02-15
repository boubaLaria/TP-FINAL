# Build stage
FROM golang:1.25-alpine AS builder

WORKDIR /app

# Copy go mod files
COPY go.mod ./

# Copy source code first (needed for go mod tidy)
COPY . .

# Download and verify dependencies
RUN go mod tidy && go mod download

# Build the application with stripped symbols for smaller binary
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -a -installsuffix cgo -o main .

# Production stage - using distroless for minimal attack surface (<20MB)
FROM gcr.io/distroless/static-debian12:nonroot

LABEL org.opencontainers.image.title="CloudShop Orders API"
LABEL org.opencontainers.image.description="Orders microservice for CloudShop"

WORKDIR /app

# Copy the binary from builder
COPY --from=builder /app/main .

# Use non-root user (provided by distroless:nonroot)
USER nonroot:nonroot

# Expose port
EXPOSE 8083

# Distroless doesn't support HEALTHCHECK in Dockerfile - handled by docker-compose

# Run the binary
ENTRYPOINT ["./main"]
