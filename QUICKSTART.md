# 🛍️ CloudShop - Plateforme E-Commerce Complète

**CloudShop** est une plateforme e-commerce moderne et scalable déployée sur Kubernetes avec une architecture microservices complet, CI/CD automatisé, et monitoring en temps réel.

![Architecture](https://img.shields.io/badge/Architecture-Microservices-blue)
![Kubernetes](https://img.shields.io/badge/Orchestration-Kubernetes-blue)
![CI/CD](https://img.shields.io/badge/CI%2FCD-GitHub%20Actions-green)
![Monitoring](https://img.shields.io/badge/Monitoring-Grafana%20%2B%20Prometheus-orange)

---

## 🎯 Vue d'Ensemble

CloudShop démontre une **architecture production-ready** avec :

- ✅ **Microservices découplés** (Node.js, Python, Go)
- ✅ **API Gateway** pour router les requêtes
- ✅ **Frontend moderne** (React + Vite)
- ✅ **Authentification sécurisée** (JWT)
- ✅ **Déploiement automatisé** sur DockerHub + VPS
- ✅ **Monitoring et Alerting** (Prometheus + Grafana)
- ✅ **GitOps** avec ArgoCD
- ✅ **Scans de sécurité** (Trivy)

---

## 🚀 Démarrage Rapide

### ⌚ 2 minutes - Local (Docker Compose)

```bash
# Cloner le projet
git clone <repo>
cd TP-FINAL

# Démarrer tous les services
docker-compose up -d

# Accéder à l'app
# Frontend: http://localhost:3000
# API: http://localhost:8080/api
```

### 🌐 5 minutes - Production (Kubernetes)

```bash
# Configurer les repos
export DOCKER_USERNAME=votre_username
export VPS_HOST=votre_vps_ip

# Déployer
make deploy

# Accéder aux services
# 🏪 CloudShop: https://cloudshop.boubalaria.com/
# 📊 Grafana: https://grafana.boubalaria.com/
# 🔄 ArgoCD: https://argo.boubalaria.com/
# 🐳 Docker Hub: https://hub.docker.com/repositories/boubalaria
```

---

## 🏗️ Architecture

### Services Microservices

| Service | Tech | Port | Description |
|---------|------|------|-------------|
| **Frontend** | React + Vite | 3000 | Interface utilisateur |
| **API Gateway** | Express.js | 8080 | Router central (JWT validation) |
| **Auth Service** | Node.js | 8081 | Authentification & tokens JWT |
| **Products API** | FastAPI (Python) | 8082 | Gestion des produits |
| **Orders API** | Go | 8083 | Gestion des commandes |
| **Elasticsearch** | Elasticsearch | 9200 | Logs et recherche |
| **PostgreSQL** | Postgres | 5432 | Base de données |

### Diagramme Architecture

```
┌─────────────────────────────────────────────────────┐
│                   FRONTEND (React)                   │
│              http://localhost:3000                   │
└────────────────────┬────────────────────────────────┘
                     │ /api
┌────────────────────▼────────────────────────────────┐
│           API GATEWAY (Express.js)                   │
│          http://localhost:8080/api                   │
│         - JWT Token Validation                       │
│         - Request Routing                            │
└──────────┬──────────┬──────────┬────────────────────┘
           │          │          │
    ┌──────▼──┐ ┌─────▼─┐  ┌────▼────┐
    │  Auth   │ │Products│  │ Orders  │
    │ Service │ │  API   │  │  API    │
    │ 8081    │ │ 8082   │  │ 8083    │
    └─────────┘ └───────┘  └─────────┘
          │           │          │
    ┌─────▼───────────▼──────────▼─────┐
    │      PostgreSQL Database          │
    │      (Auth, Products, Orders)     │
    └───────────────────────────────────┘
```

---

## 📁 Structure du Projet

```
TP-FINAL/
├── README.md                          # 📘 Documentation principale
├── QUICKSTART.md                      # 🚀 Démarrage rapide
├── DEPLOYMENT.md                      # 🔄 Déploiement détaillé
├── CI-CD-ARCHITECTURE.md              # 🏗️ Architecture CI/CD
├── INGRESS-SETUP.md                   # 🌐 Configuration Ingress
│
├── frontend/                          # React + Vite
│   ├── src/
│   │   ├── components/                # Composants React
│   │   │   ├── ProductList.jsx        # 📋 Liste des produits (avec FILTRE)
│   │   │   ├── Filter.jsx             # 🔍 Composant de filtrage
│   │   │   ├── Cart.jsx               # 🛒 Panier
│   │   │   ├── Login.jsx              # 🔐 Connexion
│   │   │   └── ...
│   │   └── services/
│   │       └── api.js                 # 📡 Appels API
│   └── Dockerfile
│
├── api-gateway/                       # API Gateway (Express)
│   ├── src/
│   │   ├── index.js                   # Point d'entrée
│   │   └── middleware/
│   │       └── auth.js                # JWT validation
│   └── Dockerfile
│
├── auth-service/                      # Service d'authentification (Node.js)
│   ├── src/
│   │   ├── index.js
│   │   ├── routes/auth.js
│   │   └── database/db.js
│   └── Dockerfile
│
├── products-api/                      # API Produits (Python/FastAPI)
│   ├── main.py
│   ├── app/
│   │   ├── database/
│   │   └── models/
│   └── Dockerfile
│
├── orders-api/                        # API Commandes (Go)
│   ├── main.go
│   ├── handlers/orders.go
│   ├── database/db.go
│   └── Dockerfile
│
├── k8s/                               # Manifests Kubernetes
│   ├── deployments/
│   │   ├── frontend.yaml
│   │   ├── api-gateway.yaml
│   │   ├── auth-service.yaml
│   │   ├── products-api.yaml
│   │   ├── orders-api.yaml
│   │   └── local/                     # Déploiement local
│   ├── services/services.yaml         # Services Kubernetes
│   ├── ingress/
│   │   ├── ingress.yaml               # Domaine (prod)
│   │   └── ingress-vps.yaml           # VPS (NodePort)
│   ├── configs/                       # ConfigMaps & Secrets
│   ├── statefulsets/                  # PostgreSQL & Elasticsearch
│   └── namespaces/
│
├── monitoring/                        # Stack de Monitoring
│   ├── dashboards/
│   │   ├── cloudshop-overview.json    # Dashboard principal
│   │   └── cloudshop-slo.json         # Dashboard SLO
│   ├── servicemonitors/               # ServiceMonitors pour Prometheus
│   ├── alerts/
│   │   └── prometheus-rules.yaml      # Règles d'alerte
│   └── namespaces/monitoring.yaml
│
├── scripts/                           # Scripts d'automatisation
│   ├── deploy.sh                      # Déploiement complet
│   ├── health-check.sh                # Vérification santé
│   ├── trivy-scan.sh                  # Scan de sécurité
│   ├── install-ingress.sh             # Installation Ingress
│   └── ...
│
├── docker-compose.yml                 # Orchestration locale
├── Makefile                           # Commandes utiles
└── .github/
    └── workflows/
        ├── ci.yml                     # Pipeline CI (tests)
        └── deploy.yml                 # Pipeline CD (production)
```

---

## 🎨 Fonctionnalités Frontend

### ✨ Nouvelles Fonctionnalités

#### 🔍 **Système de Filtrage Avancé** (Récemment Ajouté)
- Filtrer les produits par **catégorie**
- Filtrer par **plage de prix** (min/max)
- Combinaison intelligente des filtres
- Bouton "Réinitialiser" les filtres
- Interface responsive et intuitive

### 📱 Fonctionnalités Existantes

- **👥 Authentification** : Inscription / Connexion sécurisée
- **📦 Catalogue Produits** : Visualisation avec filtres
- **🛒 Panier** : Ajout/suppression d'articles
- **💳 Commande** : Formulaire de commande complète
- **📜 Historique** : Suivi des commandes passées
- **💻 Design Responsive** : Mobile, tablet, desktop

---

## 🛠️ Technologies Utilisées

### Frontend
- **React 18** - UI library
- **Vite** - Build tool & dev server
- **CSS3** - Styling moderne

### Backend Microservices
- **Node.js + Express** - API Gateway & Auth Service
- **Python + FastAPI** - Products API
- **Go** - Orders API
- **PostgreSQL** - Base de données relationnelle
- **Elasticsearch** - Logs & recherche

### DevOps & Orchestration
- **Docker** - Containerisation
- **Kubernetes** - Orchestration
- **DockerHub** - Registry
- **GitHub Actions** - CI/CD

### Monitoring & Observabilité
- **Prometheus** - Métriques
- **Grafana** - Dashboards
- **Elasticsearch** - Logs
- **Trivy** - Scan de sécurité

### Autres Tools
- **NGINX Ingress** - Routage HTTP/HTTPS
- **ArgoCD** - GitOps
- **nginx** - Web server frontend
- **JWT** - Token authentication

---

## 🔐 Authentification & Sécurité

### Flow d'Authentification

```
1. Utilisateur → Register/Login
2. Auth Service → Génère JWT token (access + refresh)
3. Client stocke le token en localStorage
4. Requêtes suivantes → JWT dans Authorization header
5. API Gateway → Valide JWT avant routage
6. Services → Requête autorisée ✅
```

### Tokens
- **Access Token** : Durée de vie courte (15-60 min)
- **Refresh Token** : Durée de vie longue (7 jours)
- **Auto-Refresh** : Renouvellement automatique des access tokens

---

## 🚀 CI/CD (GitHub Actions)

### 2 Pipelines Configurations

#### 1️⃣ **CI - Tests & Validation** (`.github/workflows/ci.yml`)
Déclenché sur : `push` + `pull_request`

```yaml
Jobs:
  1. Build images localement (tp-final-*:latest)
  2. Tests de sécurité (Trivy scan)
  3. Vérification taille images
  4. Tests d'intégration Docker Compose
```

#### 2️⃣ **CD - Production Deployment** (`.github/workflows/deploy.yml`)
Déclenché sur : `push main` uniquement

```yaml
Jobs:
  1. Build images (fresh)
  2. Push sur DockerHub (boubalaria/cloudshop-*:latest)
  3. SSH vers VPS
  4. Pull nouvelles images
  5. Restart déploiements Kubernetes
```

### Configuration GitHub Secrets

```bash
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

Voir [DEPLOYMENT.md](DEPLOYMENT.md) pour les détails complets.

---

## 📊 Monitoring & Observabilité

### Prometheus
- ✅ Scrape des métriques des microservices
- ✅ Stockage temps-réel
- ✅ Alerting basé sur des seuils

### Grafana
- 📊 **Dashboard Overview** - Vue d'ensemble système
- 📈 **Dashboard SLO** - Monitoring SLA/SLO
- 🔔 **Alertes** - Notifications en temps réel

### Logs
- 📝 Elasticsearch pour les logs centralisés
- 🔍 Kibana pour la recherche (optionnel)

### Accès

```bash
# Port-forward Prometheus
kubectl port-forward svc/prometheus 9090:9090 -n monitoring

# Port-forward Grafana
kubectl port-forward svc/grafana 3000:3000 -n monitoring
```

---

## 📋 Commandes Utiles

### Déploiement Local

```bash
# Démarrer tous les services
docker-compose up -d

# Voir les logs
docker-compose logs -f

# Arrêter tout
docker-compose down

# Rebuild images
docker-compose build --no-cache
```

### Kubernetes

```bash
# Status général
kubectl get pods -n cloudshop-prod
kubectl get svc -n cloudshop-prod

# Logs d'un service
kubectl logs deployment/frontend -n cloudshop-prod -f
kubectl logs deployment/api-gateway -n cloudshop-prod -f

# Describe un pod
kubectl describe pod <pod-name> -n cloudshop-prod

# Port forward
kubectl port-forward svc/frontend 3000:3000 -n cloudshop-prod
kubectl port-forward svc/api-gateway 8080:8080 -n cloudshop-prod
```

### Makefile

```bash
make help              # Voir toutes les commandes
make build            # Build images
make push             # Push sur DockerHub
make deploy           # Deploy complet
make k8s-status       # Status Kubernetes
make k8s-restart      # Restart services
make health-check     # Vérifier la santé
make trivy-scan       # Scan de sécurité
make check-sizes      # Taille des images
```

---

## 🌐 Accès aux Services

Après déploiement en production :

| Service | URL |
|---------|-----|
| 🏪 **CloudShop** | https://cloudshop.boubalaria.com/ |
| 📊 **Grafana** | https://grafana.boubalaria.com/ |
| 🔄 **ArgoCD** | https://argo.boubalaria.com/ |
| 🐳 **Docker Hub** | https://hub.docker.com/repositories/boubalaria |

---

## 📚 Documentation Complète

| Document | Description |
|----------|-------------|
| [QUICKSTART.md](QUICKSTART.md) | 🚀 Démarrage en 5 minutes |
| [DEPLOYMENT.md](DEPLOYMENT.md) | 🔄 Configuration détaillée CI/CD |
| [CI-CD-ARCHITECTURE.md](CI-CD-ARCHITECTURE.md) | 🏗️ Architecture pipelines |
| [INGRESS-SETUP.md](INGRESS-SETUP.md) | 🌐 Configuration Ingress |
| [monitoring/README.md](monitoring/README.md) | 📊 Stack monitoring |
| [k8s/deployments/README.md](k8s/deployments/README.md) | ☸️ Manifests Kubernetes |
| [scripts/README.md](scripts/README.md) | 🛠️ Scripts d'automatisation |

---

## 🆘 Troubleshooting

### Problème : Les pods ne démarrent pas

```bash
# Voir les logs du pod
kubectl logs <pod-name> -n cloudshop-prod

# Describe le pod pour plus de détails
kubectl describe pod <pod-name> -n cloudshop-prod

# Vérifier les events du namespace
kubectl get events -n cloudshop-prod --sort-by='.lastTimestamp'
```

### Problème : Erreur d'image Docker

```bash
# Vérifier que l'image existe sur DockerHub
docker pull boubalaria/cloudshop-frontend:latest

# Vérifier imagePullPolicy
kubectl get deployment frontend -n cloudshop-prod -o yaml | grep imagePull
```

### Problème : Pas d'accès à l'Ingress

```bash
# Vérifier l'Ingress
kubectl get ingress -n cloudshop-prod

# Vérifier le Service
kubectl get svc -n cloudshop-prod

# Port forward pour test
kubectl port-forward svc/frontend 3000:3000 -n cloudshop-prod
```

### Problème : GPU / Ressources

```bash
# Vérifier les ressources disponibles
kubectl describe nodes

# Vérifier les requêtes/limites des pods
kubectl describe pod <pod-name> -n cloudshop-prod | grep -A 10 "Requests"
```
---

## 📝 Fichiers de Configuration Importants

### `.env` - Variables d'environnement
```bash
JWT_SECRET=your-secret-key
POSTGRES_PASSWORD=your-db-password
VITE_API_URL=http://localhost:8080/api
```

### `docker-compose.yml` - Orchestration locale
Définit tous les services, ports, et dépendances.

### `Makefile` - Automatisation
Commandes shortcut pour build, deploy, health-check, etc.

### `.github/workflows/` - Pipelines CI/CD
Configurations GitHub Actions pour tests et déploiement.

---

## 📊 Métriques de Déploiement

| Métrique | Valeur |
|----------|--------|
| **Services** | 5 microservices |
| **Pods** | ~15-20 pods (avec monitoring) |
| **Namespaces** | 2 (cloudshop-prod, monitoring) |
| **Pipelines CI/CD** | 2 workflows |
| **Alerts** | 6 règles d'alerte |
| **Dashboards** | 2 dashboards Grafana |

---

## 🎓 Stack d'Apprentissage

Ce projet couvre les concepts :

- ✅ **Architecture Microservices** - Services découplés
- ✅ **Kubernetes** - Orchestration containers
- ✅ **Docker** - Containerisation
- ✅ **CI/CD** - Automated deployments
- ✅ **API Gateway** - Routage centralisé
- ✅ **JWT Authentication** - Sécurité
- ✅ **Prometheus & Grafana** - Monitoring
- ✅ **Kubernetes Ingress** - Exposition services
- ✅ **Git & GitOps** - Infrastructure as Code

---

## 📞 Support

Pour plus d'aide :

1. Vérifiez la [documentation complète](DEPLOYMENT.md)
2. Consultez les [logs des services](monitoring/README.md)
3. Lancez un health-check : `make health-check`
4. Scannez les images : `make trivy-scan`

---

## 📄 License

Ce projet est fourni à titre éducatif.

---

## 🎉 Bon Déploiement !

**CloudShop** est prêt à déployer. Consultez [QUICKSTART.md](QUICKSTART.md) pour commencer en 5 minutes !

```bash
# Let's go! 🚀
docker-compose up -d
# ou
make deploy
```

---

**Dernière mise à jour** : 24 février 2026  
**Version** : 1.0.0  
**Status** : Production Ready ✅
