# 🚀 Guide de Démarrage Rapide - CI/CD CloudShop

## Configuration en 5 Minutes

### 1️⃣ Mettre à jour les images Kubernetes

```bash
# Remplacez 'votre_username' par votre nom d'utilisateur DockerHub
make init
# OU
./scripts/update-k8s-images.sh votre_username
```

### 2️⃣ Configurer les Secrets GitHub

Allez sur GitHub : **Settings** → **Secrets and variables** → **Actions**

Ajoutez ces secrets :

```
DOCKER_USERNAME=votre_username
DOCKER_PASSWORD=votre_token_dockerhub
VPS_HOST=192.168.1.100
VPS_USERNAME=root
VPS_SSH_KEY=<contenu de votre clé privée SSH>
```

#### 🔑 Générer la clé SSH :

```bash
# Sur votre machine locale
ssh-keygen -t ed25519 -C "github-actions" -f ~/.ssh/cloudshop_deploy

# Copier la clé publique sur le VPS
ssh-copy-id -i ~/.ssh/cloudshop_deploy.pub root@192.168.1.100

# Afficher la clé privée pour GitHub Secrets
cat ~/.ssh/cloudshop_deploy
```

### 3️⃣ Pousser les changements

```bash
git add .
git commit -m "Configure CI/CD pipeline"
git push
```

✅ **C'est tout !** Le workflow GitHub Actions va automatiquement :
- Builder les images
- Les pusher sur DockerHub  
- Déployer sur votre VPS Kubernetes

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

---

## 📋 Checklist de Configuration VPS

Assurez-vous que votre VPS a :

- ✅ Docker installé : `docker --version`
- ✅ kubectl configuré : `kubectl get nodes`
- ✅ Namespace créé : `kubectl get ns cloudshop-prod`
- ✅ SSH accessible : `ssh root@VPS_IP`

Si manquant, appliquez les manifests Kubernetes :

```bash
make k8s-apply
```

---

## 🔍 Vérifier le Déploiement

### Sur GitHub
1. Allez dans l'onglet **Actions**
2. Vérifiez que le workflow est vert ✅

### Sur le VPS
```bash
ssh root@VPS_IP
kubectl get pods -n cloudshop-prod
```

Tous les pods doivent être `Running` 🟢

---

## 🆘 Problèmes Courants

### "Permission denied (publickey)"
➡️ La clé SSH n'est pas correctement configurée
```bash
ssh-copy-id -i ~/.ssh/cloudshop_deploy.pub root@VPS_IP
```

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
