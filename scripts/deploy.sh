#!/bin/bash

# Script de déploiement manuel pour CloudShop
# Usage: ./deploy.sh [OPTIONS]
# Options:
#   --build-only    - Build seulement, sans push ni deploy
#   --push-only     - Push seulement (assume que les images sont déjà buildées)
#   --deploy-only   - Deploy seulement sur le VPS

set -e

# Couleurs pour les logs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
DOCKER_USERNAME="${DOCKER_USERNAME:-}"
VPS_HOST="${VPS_HOST:-}"
VPS_USER="${VPS_USER:-root}"
VPS_SSH_PORT="${VPS_SSH_PORT:-22}"

# Services à déployer
SERVICES=("frontend" "api-gateway" "auth-service" "products-api" "orders-api")

# Fonctions utilitaires
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Vérifier les variables d'environnement
check_env() {
    if [ -z "$DOCKER_USERNAME" ]; then
        log_error "DOCKER_USERNAME n'est pas défini"
        log_info "Exportez DOCKER_USERNAME avec: export DOCKER_USERNAME=your_username"
        exit 1
    fi
    
    if [ "$1" != "--build-only" ] && [ "$1" != "--push-only" ]; then
        if [ -z "$VPS_HOST" ]; then
            log_error "VPS_HOST n'est pas défini"
            log_info "Exportez VPS_HOST avec: export VPS_HOST=your_vps_ip"
            exit 1
        fi
    fi
}

# Build toutes les images
build_images() {
    log_info "🔨 Building Docker images..."
    
    for service in "${SERVICES[@]}"; do
        log_info "Building $service..."
        
        case $service in
            "frontend")
                docker build -t $DOCKER_USERNAME/cloudshop-frontend:latest ./frontend
                ;;
            "api-gateway")
                docker build -t $DOCKER_USERNAME/cloudshop-api-gateway:latest ./api-gateway
                ;;
            "auth-service")
                docker build -t $DOCKER_USERNAME/cloudshop-auth-service:latest ./auth-service
                ;;
            "products-api")
                docker build -t $DOCKER_USERNAME/cloudshop-products-api:latest ./products-api
                ;;
            "orders-api")
                docker build -t $DOCKER_USERNAME/cloudshop-orders-api:latest ./orders-api
                ;;
        esac
        
        log_info "✅ $service built successfully"
    done
    
    log_info "🎉 All images built successfully!"
}

# Push toutes les images sur DockerHub
push_images() {
    log_info "📤 Pushing images to DockerHub..."
    
    # Login to DockerHub
    log_info "Logging in to DockerHub..."
    docker login
    
    for service in "${SERVICES[@]}"; do
        log_info "Pushing cloudshop-$service..."
        docker push $DOCKER_USERNAME/cloudshop-$service:latest
        log_info "✅ cloudshop-$service pushed successfully"
    done
    
    log_info "🎉 All images pushed successfully!"
}

# Déployer sur le VPS
deploy_to_vps() {
    log_info "🚀 Deploying to VPS..."
    
    ssh -p $VPS_SSH_PORT $VPS_USER@$VPS_HOST << 'ENDSSH'
        set -e
        
        echo "Pulling new Docker images..."
        docker pull ${DOCKER_USERNAME}/cloudshop-frontend:latest
        docker pull ${DOCKER_USERNAME}/cloudshop-api-gateway:latest
        docker pull ${DOCKER_USERNAME}/cloudshop-auth-service:latest
        docker pull ${DOCKER_USERNAME}/cloudshop-products-api:latest
        docker pull ${DOCKER_USERNAME}/cloudshop-orders-api:latest
        
        echo "Restarting Kubernetes deployments..."
        kubectl rollout restart deployment/frontend -n cloudshop-prod
        kubectl rollout restart deployment/api-gateway -n cloudshop-prod
        kubectl rollout restart deployment/auth-service -n cloudshop-prod
        kubectl rollout restart deployment/orders-api -n cloudshop-prod
        kubectl rollout restart deployment/products-api -n cloudshop-prod
        
        echo "Waiting for deployments to be ready..."
        kubectl rollout status deployment/frontend -n cloudshop-prod --timeout=300s
        kubectl rollout status deployment/api-gateway -n cloudshop-prod --timeout=300s
        kubectl rollout status deployment/auth-service -n cloudshop-prod --timeout=300s
        kubectl rollout status deployment/orders-api -n cloudshop-prod --timeout=300s
        kubectl rollout status deployment/products-api -n cloudshop-prod --timeout=300s
        
        echo "Checking pod status..."
        kubectl get pods -n cloudshop-prod
        
        echo "Deployment completed successfully!"
ENDSSH
    
    log_info "🎉 Deployment to VPS completed successfully!"
}

# Main
main() {
    log_info "🚢 CloudShop Deployment Script"
    log_info "================================"
    
    case "$1" in
        --build-only)
            check_env "$1"
            build_images
            ;;
        --push-only)
            check_env "$1"
            push_images
            ;;
        --deploy-only)
            check_env "$1"
            deploy_to_vps
            ;;
        *)
            check_env
            build_images
            push_images
            deploy_to_vps
            ;;
    esac
    
    log_info "✨ Done!"
}

main "$@"
