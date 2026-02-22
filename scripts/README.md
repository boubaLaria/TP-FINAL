# Scripts de Déploiement CloudShop

Ce dossier contient les scripts utiles pour le déploiement de CloudShop.

## 📜 Scripts Disponibles

### `deploy.sh`
Script principal de déploiement manuel.

**Usage:**
```bash
# Déploiement complet
export DOCKER_USERNAME="myusername"
export VPS_HOST="192.168.1.100"
./deploy.sh

# Options
./deploy.sh --build-only     # Build seulement
./deploy.sh --push-only      # Push seulement
./deploy.sh --deploy-only    # Deploy seulement
```

### `update-k8s-images.sh`
Met à jour les manifests Kubernetes pour utiliser vos images DockerHub.

**Usage:**
```bash
./update-k8s-images.sh <DOCKER_USERNAME>

# Exemple
./update-k8s-images.sh myusername
```

Ce script va :
- Remplacer `cloudshop/service:latest` par `myusername/cloudshop-service:latest`
- Changer `imagePullPolicy: Never` en `imagePullPolicy: Always`

**⚠️ Important:** Exécutez ce script AVANT le premier déploiement !

### `health-check.sh`
Vérifie la santé des services.

**Usage:**
```bash
./health-check.sh
```

### `trivy-scan.sh`
Scan de sécurité des images Docker avec Trivy.

**Usage:**
```bash
./trivy-scan.sh
```

### `check-image-sizes.sh`
Vérifie la taille des images Docker.

**Usage:**
```bash
./check-image-sizes.sh
```

## 🚀 Workflow de Déploiement Recommandé

### Configuration Initiale

1. **Mettre à jour les manifests K8s:**
   ```bash
   ./scripts/update-k8s-images.sh YOUR_DOCKER_USERNAME
   ```

2. **Commit les changements:**
   ```bash
   git add k8s/deployments/
   git commit -m "Update Docker images for CI/CD"
   ```

3. **Configurer les secrets GitHub** (voir [DEPLOYMENT.md](../DEPLOYMENT.md))

4. **Push pour déclencher le déploiement:**
   ```bash
   git push
   ```

### Déploiement Manuel

Si vous préférez le déploiement manuel :

```bash
# Configurer les variables
export DOCKER_USERNAME="myusername"
export VPS_HOST="192.168.1.100"
export VPS_USER="root"

# Déployer
./scripts/deploy.sh
```

## 📚 Documentation Complète

Pour plus de détails, consultez [DEPLOYMENT.md](../DEPLOYMENT.md)
