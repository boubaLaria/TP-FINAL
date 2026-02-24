# 🚀 Guide de Démarrage Rapide - CI/CD CloudShop

> 📘 **Documentation Principale** : Consultez [README.md](README.md) pour une vue d'ensemble complète du projet.

## 🎯 Architecture CI/CD

**2 workflows séparés pour éviter la duplication** :

### 1️⃣ CI - Tests & Validation (`.github/workflows/ci.yml`)
- ✅ Se déclenche sur tous les push et PRs
- ✅ Build les images **localement** (`tp-final-*:latest`)
- ✅ Tests, scans de sécurité, vérification de taille
- ❌ **NE PUSH PAS** sur DockerHub
- 🎯 **But** : Valider le code rapidement sans surcharger DockerHub

### 2️⃣ CD - Production (`.github/workflows/deploy.yml`)  
- ✅ Se déclenche uniquement sur push `main` (après CI)
- ✅ Build les images **fresh**
- ✅ Push sur DockerHub (`boubalaria/cloudshop-*:latest`)
- ✅ Deploy automatique sur le VPS
- 🎯 **But** : Déployer en production avec garantie de fraîcheur

---

## Configuration en 5 Minutes

### 1️⃣ Pas de modification nécessaire !

Les manifests Kubernetes sont déjà configurés avec `boubalaria` pour la production ! ✅

**Deux environnements disponibles** :
- `k8s/deployments/` - **Production** (DockerHub : `boubalaria/cloudshop-*`)
- `k8s/deployments/local/` - **Local/Dev** (Images locales : `tp-final-*`)

### 2️⃣ Configurer les Secrets GitHub

Allez sur GitHub : **Settings** → **Secrets and variables** → **Actions**

Ajoutez ces secrets :

```
DOCKER_USERNAME=votre_username
DOCKER_PASSWORD=votre_token_dockerhub
```

### 3️⃣ Pousser les changements

```bash
git add .
git commit -m "Configure CI/CD pipeline"
git push origin develop  # CI seulement (tests)
# OU
git push origin main     # CI + CD (tests + déploiement prod)
```

✅ **Workflows déclenchés** :
- Sur `develop` / PR : **CI uniquement** (build local + tests)
- Sur `main` : **CI + CD** (tests + build + push DockerHub + deploy VPS)

---

## 📱 Déploiement Manuel (Alternative)

Si vous préférez déployer manuellement :

```bash
# 1. Configurer les variables
export DOCKER_USERNAME="votre_username"
export VPS_HOST="192.168.1.100"

# 2. Déployer
make deploy
# OU
./scripts/deploy.sh
```

---

## 🛠️ Commandes Utiles

```bash
# Voir toutes les commandes disponibles
make help

# Status Kubernetes
make k8s-status

# Redémarrer les services
make k8s-restart

# Voir les logs
make k8s-logs SERVICE=frontend

# Local avec Docker Compose
make docker-compose-up
make docker-compose-logs
```

## 🌐 Accès aux Services

Après déploiement, accédez à vos services :

- 🏪 **CloudShop** : https://cloudshop.boubalaria.com/
- 📊 **Grafana** : https://grafana.boubalaria.com/
- 🔄 **ArgoCD** : https://argo.boubalaria.com/
- 🐳 **Docker Hub** : https://hub.docker.com/repositories/boubalaria

---

## 🔍 Vérifier le Déploiement

### Sur GitHub
1. Allez dans l'onglet **Actions**
2. Vérifiez que le workflow est vert ✅

---

## 🆘 Problèmes Courants

### "deployment.apps/frontend not found"
➡️ Appliquez d'abord les manifests K8s
```bash
make k8s-apply
```

### Les pods ne démarrent pas
➡️ Vérifiez les logs
```bash
kubectl logs deployment/frontend -n cloudshop-prod
```

---

## 📚 Documentation Complète

Pour plus de détails : [DEPLOYMENT.md](DEPLOYMENT.md)

---

**Bon déploiement ! 🎉**
