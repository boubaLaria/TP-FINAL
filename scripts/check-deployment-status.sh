#!/bin/bash

# Script pour vérifier l'état du déploiement sur le VPS
# Usage: ./check-deployment-status.sh

set -e

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}==================================${NC}"
echo -e "${GREEN}CloudShop - Deployment Status${NC}"
echo -e "${GREEN}==================================${NC}"
echo ""

# Namespaces
echo -e "${YELLOW}📦 Namespaces:${NC}"
kubectl get namespaces | grep cloudshop || echo "No cloudshop namespaces found"
echo ""

# StatefulSets
echo -e "${YELLOW}💾 StatefulSets (Database, Elasticsearch):${NC}"
kubectl get statefulsets -n cloudshop-prod
echo ""

# Deployments
echo -e "${YELLOW}🚀 Deployments:${NC}"
kubectl get deployments -n cloudshop-prod
echo ""

# Pods avec détails
echo -e "${YELLOW}🔷 Pods Status:${NC}"
kubectl get pods -n cloudshop-prod -o wide
echo ""

# Services
echo -e "${YELLOW}🌐 Services:${NC}"
kubectl get services -n cloudshop-prod
echo ""

# Ingress
echo -e "${YELLOW}🔀 Ingress:${NC}"
kubectl get ingress -n cloudshop-prod
echo ""

# Vérifier les pods en erreur
FAILED_PODS=$(kubectl get pods -n cloudshop-prod --field-selector=status.phase!=Running,status.phase!=Succeeded 2>/dev/null | tail -n +2)

if [ -n "$FAILED_PODS" ]; then
    echo -e "${RED}⚠️  Pods with Issues:${NC}"
    echo "$FAILED_PODS"
    echo ""
    
    echo -e "${YELLOW}Recent Events:${NC}"
    kubectl get events -n cloudshop-prod --sort-by='.lastTimestamp' | tail -20
    echo ""
fi

# Résumé
echo -e "${GREEN}==================================${NC}"
echo -e "${GREEN}Summary${NC}"
echo -e "${GREEN}==================================${NC}"

TOTAL_PODS=$(kubectl get pods -n cloudshop-prod --no-headers 2>/dev/null | wc -l)
RUNNING_PODS=$(kubectl get pods -n cloudshop-prod --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l)
PENDING_PODS=$(kubectl get pods -n cloudshop-prod --field-selector=status.phase=Pending --no-headers 2>/dev/null | wc -l)

echo -e "Total Pods: ${YELLOW}$TOTAL_PODS${NC}"
echo -e "Running: ${GREEN}$RUNNING_PODS${NC}"
echo -e "Pending: ${YELLOW}$PENDING_PODS${NC}"
echo ""

if [ "$RUNNING_PODS" -eq "$TOTAL_PODS" ] && [ "$TOTAL_PODS" -gt 0 ]; then
    echo -e "${GREEN}✅ All pods are running!${NC}"
else
    echo -e "${YELLOW}⏳ Some pods are still starting or have issues${NC}"
    echo ""
    echo -e "${YELLOW}Troubleshooting commands:${NC}"
    echo "  kubectl describe pod <pod-name> -n cloudshop-prod"
    echo "  kubectl logs <pod-name> -n cloudshop-prod"
    echo "  kubectl logs <pod-name> -n cloudshop-prod --previous"
fi

echo ""
