# 🚀 Guide de Déploiement CI/CD CloudShop

Ce guide explique comment configurer et utiliser le pipeline CI/CD pour déployer automatiquement CloudShop sur DockerHub et votre VPS Kubernetes.

## 📋 Table des Matières

- [Architecture CI/CD](#architecture-cicd)
- [Configuration GitHub Actions](#configuration-github-actions)
- [Déploiement Manuel](#déploiement-manuel)
- [Secrets Requis](#secrets-requis)
- [Troubleshooting](#troubleshooting)

## 🏗️ Architecture CI/CD

Le pipeline CI/CD se compose de deux jobs principaux :

1. **Build and Push** : Build toutes les images Docker et les push sur DockerHub
2. **Deploy to VPS** : Se connecte au VPS via SSH, pull les nouvelles images et redémarre les déploiements Kubernetes

### Services Déployés

- `cloudshop-frontend` - Application React + Vite
- `cloudshop-api-gateway` - API Gateway Express
- `cloudshop-auth-service` - Service d'authentification Node.js
- `cloudshop-products-api` - API Produits FastAPI (Python)
- `cloudshop-orders-api` - API Commandes Go

## ⚙️ Configuration GitHub Actions

### 1. Configurer les Secrets GitHub

Allez dans votre repository GitHub : **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

#### Secrets Obligatoires :

| Secret | Description | Exemple |
|--------|-------------|---------|
| `DOCKER_USERNAME` | Nom d'utilisateur DockerHub | `myusername` |
| `DOCKER_PASSWORD` | Mot de passe DockerHub ou Token | `dckr_pat_xxxxx` |
| `VPS_HOST` | IP ou domaine du VPS | `192.168.1.100` ou `vps.example.com` |
| `VPS_USERNAME` | Utilisateur SSH du VPS | `root` ou `ubuntu` |
| `VPS_SSH_KEY` | Clé privée SSH (contenu complet) | Voir ci-dessous |
| `VPS_SSH_PORT` | Port SSH (optionnel, défaut: 22) | `22` |

### 2. Générer et Configurer la Clé SSH

Sur votre machine locale :

```bash
# Générer une nouvelle paire de clés SSH (si nécessaire)
ssh-keygen -t ed25519 -C "github-actions" -f ~/.ssh/cloudshop_deploy

# Copier la clé publique sur le VPS
ssh-copy-id -i ~/.ssh/cloudshop_deploy.pub user@vps_host

# Afficher la clé privée pour la copier dans GitHub Secrets
cat ~/.ssh/cloudshop_deploy
```

⚠️ **Important** : Copiez **tout** le contenu de la clé privée, y compris les lignes `-----BEGIN` et `-----END`.

### 3. Configurer le VPS

Sur votre VPS, assurez-vous que :

#### Docker est installé et configuré :

```bash
# Vérifier Docker
docker --version

# Vérifier que l'utilisateur peut utiliser Docker
docker ps
```

#### Kubernetes (kubectl) est configuré :

```bash
# Vérifier kubectl
kubectl version --client

# Vérifier l'accès au cluster
kubectl get nodes

# Vérifier le namespace cloudshop-prod
kubectl get namespaces | grep cloudshop-prod
```

#### Les déploiements Kubernetes utilisent les bonnes images :

Mettez à jour vos fichiers de déploiement Kubernetes pour utiliser vos images DockerHub :

```yaml
# Exemple pour k8s/deployments/frontend.yaml
spec:
  containers:
  - name: frontend
    image: YOUR_DOCKER_USERNAME/cloudshop-frontend:latest
    imagePullPolicy: Always
```

Remplacez `YOUR_DOCKER_USERNAME` par votre nom d'utilisateur DockerHub dans tous les fichiers :
- `k8s/deployments/frontend.yaml`
- `k8s/deployments/api-gateway.yaml`
- `k8s/deployments/auth-service.yaml`
- `k8s/deployments/orders-api.yaml`
- `k8s/deployments/products-api.yaml`

### 4. Déployer l'Application

Le workflow GitHub Actions se déclenche automatiquement :

- ✅ À chaque `push` sur les branches `main` ou `master`
- ✅ Manuellement depuis l'onglet **Actions** → **Build, Push and Deploy to Kubernetes** → **Run workflow**

## 🛠️ Déploiement Manuel

Si vous préférez déployer manuellement ou pour tester localement, utilisez le script `deploy.sh` :

### Configuration

Exportez les variables d'environnement nécessaires :

```bash
export DOCKER_USERNAME="votre_username_dockerhub"
export VPS_HOST="192.168.1.100"  # IP de votre VPS
export VPS_USER="root"            # Utilisateur SSH (défaut: root)
export VPS_SSH_PORT="22"          # Port SSH (défaut: 22)
```

### Utilisation

```bash
# Déploiement complet (build + push + deploy)
./scripts/deploy.sh

# Build seulement
./scripts/deploy.sh --build-only

# Push seulement (les images doivent déjà être buildées)
./scripts/deploy.sh --push-only

# Deploy seulement (les images doivent être sur DockerHub)
./scripts/deploy.sh --deploy-only
```

### Exemple d'utilisation complète

```bash
cd /Users/laria/ynov/docker-cours/TP-FINAL

# Configurer les variables
export DOCKER_USERNAME="myusername"
export VPS_HOST="192.168.1.100"

# Déployer
./scripts/deploy.sh
```

## 🔐 Secrets Requis - Récapitulatif

### Pour GitHub Actions

Configurez ces secrets dans GitHub : **Settings** → **Secrets and variables** → **Actions**

```
DOCKER_USERNAME=myusername
DOCKER_PASSWORD=dckr_pat_xxxxxxxxxxxxx
VPS_HOST=192.168.1.100
VPS_USERNAME=root
VPS_SSH_KEY=-----BEGIN OPENSSH PRIVATE KEY-----
...
-----END OPENSSH PRIVATE KEY-----
VPS_SSH_PORT=22
```

### Pour le Déploiement Manuel

Exportez ces variables d'environnement :

```bash
export DOCKER_USERNAME="myusername"
export VPS_HOST="192.168.1.100"
export VPS_USER="root"
export VPS_SSH_PORT="22"
```

## 🐛 Troubleshooting

### Erreur : "Permission denied (publickey)"

➡️ La clé SSH n'est pas correctement configurée
- Vérifiez que la clé publique est dans `~/.ssh/authorized_keys` sur le VPS
- Testez la connexion : `ssh -i ~/.ssh/cloudshop_deploy user@vps_host`

### Erreur : "Cannot connect to the Docker daemon"

➡️ Docker n'est pas accessible à l'utilisateur SSH
```bash
# Sur le VPS, ajouter l'utilisateur au groupe docker
sudo usermod -aG docker $USER
```

### Erreur : "The connection to the server localhost:8080 was refused"

➡️ kubectl n'est pas configuré correctement
```bash
# Vérifier la configuration kubectl
kubectl cluster-info
cat ~/.kube/config
```

### Erreur : "deployment.apps/frontend not found"

➡️ Les déploiements Kubernetes n'existent pas encore
```bash
# Appliquer les manifests Kubernetes d'abord
kubectl apply -f k8s/namespaces/
kubectl apply -f k8s/configs/
kubectl apply -f k8s/deployments/
kubectl apply -f k8s/services/
```

### Les pods ne démarrent pas après le déploiement

➡️ Vérifier les logs des pods
```bash
# Lister les pods
kubectl get pods -n cloudshop-prod

# Voir les logs d'un pod
kubectl logs POD_NAME -n cloudshop-prod

# Décrire un pod pour voir les événements
kubectl describe pod POD_NAME -n cloudshop-prod
```

### Images non trouvées sur DockerHub

➡️ Vérifier que les images sont bien publiques
- Connectez-vous à DockerHub
- Allez dans **Repositories**
- Vérifiez que les repositories `cloudshop-*` existent et sont publics

### Le workflow GitHub Actions échoue

➡️ Vérifier les logs dans GitHub
- Allez dans l'onglet **Actions**
- Cliquez sur le workflow qui a échoué
- Examinez les logs de chaque step

## 📊 Monitoring

### Vérifier l'état du déploiement

```bash
# Status des déploiements
kubectl get deployments -n cloudshop-prod

# Status des pods
kubectl get pods -n cloudshop-prod

# Logs d'un service
kubectl logs -f deployment/frontend -n cloudshop-prod
```

### Rollback en cas de problème

```bash
# Voir l'historique des déploiements
kubectl rollout history deployment/frontend -n cloudshop-prod

# Rollback à la version précédente
kubectl rollout undo deployment/frontend -n cloudshop-prod
```

## 🎯 Bonnes Pratiques

1. **Tags de version** : Utilisez des tags de version spécifiques au lieu de `latest` en production
2. **Health checks** : Configurez des liveness et readiness probes dans Kubernetes
3. **Secrets Kubernetes** : Utilisez des secrets Kubernetes pour les variables sensibles
4. **Resource limits** : Définissez des limites de ressources pour chaque pod
5. **Rolling updates** : Kubernetes fait des rolling updates par défaut, mais configurez `maxUnavailable` et `maxSurge`

## 📝 Notes

- Le workflow utilise Docker Buildx avec cache pour accélérer les builds
- Les images sont taguées avec `latest` ET le SHA du commit git
- Le déploiement attend jusqu'à 5 minutes que chaque service soit prêt
- Les pulls d'images utilisent le tag `latest`

## 🔗 Ressources Utiles

- [Documentation GitHub Actions](https://docs.github.com/en/actions)
- [Documentation Kubernetes](https://kubernetes.io/docs/home/)
- [Docker Hub](https://hub.docker.com/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)

---

**Créé le** : 22 février 2026
**Projet** : CloudShop - TP Final Docker/Kubernetes
