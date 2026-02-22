#!/bin/bash

# Script pour mettre à jour les images Docker dans les manifests Kubernetes
# Usage: ./update-k8s-images.sh <DOCKER_USERNAME>

set -e

# Couleurs pour les logs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Vérifier les arguments
if [ -z "$1" ]; then
    log_error "Usage: $0 <DOCKER_USERNAME>"
    log_info "Example: $0 myusername"
    exit 1
fi

DOCKER_USERNAME=$1
K8S_DIR="k8s/deployments"

log_info "🔄 Updating Kubernetes deployment manifests..."
log_info "Docker Username: $DOCKER_USERNAME"

# Vérifier que le répertoire existe
if [ ! -d "$K8S_DIR" ]; then
    log_error "Directory $K8S_DIR not found!"
    exit 1
fi

# Fonction pour mettre à jour un fichier
update_deployment() {
    local file=$1
    local service=$2
    
    log_info "Updating $file..."
    
    # Mettre à jour l'image et imagePullPolicy
    sed -i.bak "s|image: cloudshop/$service:latest|image: $DOCKER_USERNAME/cloudshop-$service:latest|g" "$file"
    sed -i.bak "s|imagePullPolicy: Never|imagePullPolicy: Always|g" "$file"
    
    # Supprimer le fichier de backup
    rm -f "$file.bak"
    
    log_info "✅ $file updated"
}

# Mettre à jour tous les fichiers de déploiement
update_deployment "$K8S_DIR/frontend.yaml" "frontend"
update_deployment "$K8S_DIR/api-gateway.yaml" "api-gateway"
update_deployment "$K8S_DIR/auth-service.yaml" "auth-service"
update_deployment "$K8S_DIR/orders-api.yaml" "orders-api"
update_deployment "$K8S_DIR/products-api.yaml" "products-api"

log_info "🎉 All deployment manifests updated successfully!"
log_info ""
log_info "📝 Next steps:"
log_info "1. Review the changes: git diff k8s/deployments/"
log_info "2. Commit the changes: git add k8s/deployments/ && git commit -m 'Update Docker images for CI/CD'"
log_info "3. Push to trigger deployment: git push"
