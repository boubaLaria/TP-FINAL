#!/bin/bash

# Script pour basculer vers hostPath storage (pour VPS sans StorageClass)
# Usage: ./fix-storage.sh

set -e

echo "🔧 Fixing storage issues - switching to hostPath..."

# Supprimer les Services pour éviter les conflits
echo "Preserving Services (will be recreated)..."  

# Supprimer les StatefulSets existants avec FORCE
echo "Force deleting existing StatefulSets..."
kubectl delete statefulset postgres -n cloudshop-prod --cascade=orphan --ignore-not-found=true
kubectl delete statefulset elasticsearch -n cloudshop-prod --cascade=orphan --ignore-not-found=true

# Supprimer les pods orphelins
echo "Cleaning up pods..."
kubectl delete pod postgres-0 -n cloudshop-prod --force --grace-period=0 --ignore-not-found=true
kubectl delete pod elasticsearch-0 -n cloudshop-prod --force --grace-period=0 --ignore-not-found=true

# Supprimer les PVCs bloqués
echo "Cleaning up PVCs..."
kubectl delete pvc --all -n cloudshop-prod --ignore-not-found=true --timeout=30s || true

# Créer les dossiers de stockage
echo "Creating storage directories..."
sudo mkdir -p /data/postgres /data/elasticsearch
sudo chmod 777 /data/postgres /data/elasticsearch

# Attendre un peu
echo "Waiting for cleanup..."
sleep 10

# Appliquer les nouvelles versions avec hostPath
echo "Applying hostPath StatefulSets..."
kubectl apply -f k8s/statefulsets/postgres-hostpath.yaml
kubectl apply -f k8s/statefulsets/elasticsearch-hostpath.yaml

echo ""
echo "✅ Storage fix applied!"
echo ""
echo "Checking status..."
kubectl get pods -n cloudshop-prod

echo ""
echo "Monitor with: kubectl get pods -n cloudshop-prod -w"
