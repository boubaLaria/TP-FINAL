#!/bin/bash

# Script pour basculer vers hostPath storage (pour VPS sans StorageClass)
# Usage: ./fix-storage.sh

set -e

echo "🔧 Fixing storage issues - switching to hostPath..."

# Supprimer les StatefulSets existants
echo "Deleting existing StatefulSets..."
kubectl delete statefulset postgres -n cloudshop-prod --ignore-not-found=true
kubectl delete statefulset elasticsearch -n cloudshop-prod --ignore-not-found=true

# Supprimer les PVCs bloqués
echo "Cleaning up PVCs..."
kubectl delete pvc --all -n cloudshop-prod --ignore-not-found=true

# Créer les dossiers de stockage
echo "Creating storage directories..."
sudo mkdir -p /data/postgres /data/elasticsearch
sudo chmod 777 /data/postgres /data/elasticsearch

# Attendre un peu
sleep 5

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
