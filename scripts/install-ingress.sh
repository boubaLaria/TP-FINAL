#!/bin/bash

# Script pour installer NGINX Ingress Controller sur Kubernetes
# Usage: ./install-ingress.sh

set -e

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Installing NGINX Ingress Controller${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Vérifier si kubectl est disponible
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}Error: kubectl not found${NC}"
    exit 1
fi

# Installer NGINX Ingress Controller
echo -e "${YELLOW}Installing NGINX Ingress Controller...${NC}"
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.10.0/deploy/static/provider/cloud/deploy.yaml

echo ""
echo -e "${YELLOW}Waiting for Ingress Controller to be ready...${NC}"
echo "This may take a few minutes..."

# Attendre que le namespace soit créé
sleep 5

# Attendre que les pods soient prêts
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=300s || echo -e "${YELLOW}Timeout waiting for pods, but continuing...${NC}"

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Checking Ingress Controller Status${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Afficher les pods
echo -e "${YELLOW}Ingress Controller Pods:${NC}"
kubectl get pods -n ingress-nginx

echo ""
echo -e "${YELLOW}Ingress Controller Services:${NC}"
kubectl get svc -n ingress-nginx

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✅ Installation Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Récupérer l'External IP ou NodePort
EXTERNAL_IP=$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
NODEPORT_HTTP=$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.spec.ports[?(@.name=="http")].nodePort}' 2>/dev/null || echo "")
NODEPORT_HTTPS=$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.spec.ports[?(@.name=="https")].nodePort}' 2>/dev/null || echo "")

if [ -n "$EXTERNAL_IP" ]; then
    echo -e "${YELLOW}External IP:${NC} $EXTERNAL_IP"
    echo -e "${YELLOW}Access your application at:${NC} http://$EXTERNAL_IP"
elif [ -n "$NODEPORT_HTTP" ]; then
    echo -e "${YELLOW}NodePort HTTP:${NC} $NODEPORT_HTTP"
    echo -e "${YELLOW}NodePort HTTPS:${NC} $NODEPORT_HTTPS"
    echo -e "${YELLOW}Access your application at:${NC} http://<VPS_IP>:$NODEPORT_HTTP"
else
    echo -e "${YELLOW}Note: No External IP or NodePort found. Check the service configuration.${NC}"
fi

echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Update /etc/hosts or DNS with your domain"
echo "2. Apply your Ingress resource: kubectl apply -f k8s/ingress/"
echo "3. Test access: curl -H 'Host: <your-domain>' http://<VPS_IP>"
echo ""
