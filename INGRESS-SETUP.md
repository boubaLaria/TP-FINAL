# 🌐 Guide d'Installation et Configuration Ingress

Ce guide explique comment installer et configurer NGINX Ingress Controller sur votre VPS Kubernetes.

## 📋 Table des Matières

1. [Qu'est-ce qu'un Ingress ?](#quest-ce-quun-ingress)
2. [Installation du Controller](#installation-du-controller)
3. [Configuration pour VPS](#configuration-pour-vps)
4. [Test et Vérification](#test-et-vérification)
5. [Troubleshooting](#troubleshooting)

---

## 🎯 Qu'est-ce qu'un Ingress ?

Un **Ingress** est un objet Kubernetes qui gère l'accès externe à vos services via HTTP/HTTPS.

**Sans Ingress:**
```
Internet → NodePort:30080 → Service → Pods
         → NodePort:30081 → Service → Pods
         → NodePort:30082 → Service → Pods
```

**Avec Ingress:**
```
Internet → Ingress (Port 80/443) → Routes intelligentes → Services → Pods
```

**Avantages:**
- ✅ Un seul point d'entrée (port 80/443)
- ✅ Routage basé sur le domaine ou le path
- ✅ Support SSL/TLS
- ✅ Load balancing

---

## 🚀 Installation du Controller

### Méthode 1 : Script Automatique (Recommandé)

Sur votre **VPS** :

```bash
cd ~/cloudshop-deploy
./scripts/install-ingress.sh
```

### Méthode 2 : Installation Manuelle

```bash
# Installer NGINX Ingress Controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.10.0/deploy/static/provider/cloud/deploy.yaml

# Attendre que les pods soient prêts
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=300s

# Vérifier l'installation
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx
```

### 📊 Vérifier le Service

```bash
kubectl get svc ingress-nginx-controller -n ingress-nginx
```

**Output typique pour un VPS (NodePort):**
```
NAME                       TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)
ingress-nginx-controller   LoadBalancer   10.43.x.x       <pending>     80:30080/TCP,443:30443/TCP
```

- `80:30080` → HTTP accessible sur le port **30080**
- `443:30443` → HTTPS accessible sur le port **30443**

---

## ⚙️ Configuration pour VPS

Vous avez **3 options** selon votre setup :

### Option 1 : Accès Direct par IP (Simple, pas de domaine)

**Fichier:** `k8s/ingress/ingress-vps.yaml`

```yaml
# Accès: http://VPS_IP:30080/
# Frontend: http://VPS_IP:30080/
# API: http://VPS_IP:30080/api
```

**Appliquer:**
```bash
kubectl apply -f k8s/ingress/ingress-vps.yaml
```

**Tester:**
```bash
curl http://VPS_IP:30080/
curl http://VPS_IP:30080/api/health
```

### Option 2 : Avec Nom de Domaine

**Fichier:** `k8s/ingress/ingress-domain.yaml`

1. **Éditez le fichier** et remplacez `YOUR_DOMAIN` :
   ```yaml
   - host: cloudshop.example.com  # Votre domaine
   ```

2. **Configurez votre DNS** :
   ```
   cloudshop.example.com  →  A  →  VPS_IP
   ```

3. **Appliquer:**
   ```bash
   kubectl apply -f k8s/ingress/ingress-domain.yaml
   ```

4. **Tester:**
   ```bash
   curl http://cloudshop.example.com
   ```

### Option 3 : Test Local avec /etc/hosts

Si vous n'avez pas de domaine, simulez-en un localement :

1. **Sur votre machine locale**, éditez `/etc/hosts` :
   ```bash
   sudo nano /etc/hosts
   ```

2. **Ajoutez** :
   ```
   VPS_IP  cloudshop.local
   VPS_IP  api.local
   ```

3. **Appliquer l'Ingress original** :
   ```bash
   kubectl apply -f k8s/ingress/ingress.yaml
   ```

4. **Tester depuis votre machine** :
   ```bash
   curl http://cloudshop.local:30080/
   ```

---

## 🔍 Architecture des Routes

### Option VPS (ingress-vps.yaml)
```
http://VPS_IP:30080/          → Frontend (React)
http://VPS_IP:30080/api       → API Gateway
```

### Option Domaine (ingress-domain.yaml)
```
http://cloudshop.example.com/     → Frontend
http://cloudshop.example.com/api  → API Gateway
```

### Option Multi-Domaines (ingress.yaml)
```
http://shop.local/    → Frontend
http://api.local/     → API Gateway
```

---

## ✅ Test et Vérification

### 1. Vérifier le Controller

```bash
# Pods du controller
kubectl get pods -n ingress-nginx

# Service et ports
kubectl get svc ingress-nginx-controller -n ingress-nginx

# Logs du controller
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller
```

### 2. Vérifier votre Ingress

```bash
# Liste des Ingress
kubectl get ingress -n cloudshop-prod

# Détails
kubectl describe ingress cloudshop-ingress -n cloudshop-prod
```

**Output attendu:**
```
Name:             cloudshop-ingress
Namespace:        cloudshop-prod
Address:          10.43.x.x
Rules:
  Host        Path  Backends
  ----        ----  --------
  *
              /      frontend:3000
              /api   api-gateway:8080
```

### 3. Tests d'Accès

```bash
# Test Frontend
curl -v http://VPS_IP:30080/

# Test API
curl -v http://VPS_IP:30080/api/health

# Test avec domaine (si configuré)
curl -H "Host: cloudshop.example.com" http://VPS_IP:30080/
```

### 4. Tester depuis un Navigateur

Ouvrez votre navigateur :
- Frontend : `http://VPS_IP:30080/`
- API : `http://VPS_IP:30080/api/health`

---

## 🔧 Configuration Avancée

### Rediriger HTTP → HTTPS (Production)

```yaml
annotations:
  nginx.ingress.kubernetes.io/ssl-redirect: "true"
  cert-manager.io/cluster-issuer: "letsencrypt-prod"
```

### Rate Limiting

```yaml
annotations:
  nginx.ingress.kubernetes.io/limit-rps: "10"
```

### Timeout Personnalisé

```yaml
annotations:
  nginx.ingress.kubernetes.io/proxy-connect-timeout: "600"
  nginx.ingress.kubernetes.io/proxy-send-timeout: "600"
  nginx.ingress.kubernetes.io/proxy-read-timeout: "600"
```

### CORS

```yaml
annotations:
  nginx.ingress.kubernetes.io/enable-cors: "true"
  nginx.ingress.kubernetes.io/cors-allow-origin: "*"
```

---

## 🐛 Troubleshooting

### Problème : "502 Bad Gateway"

**Cause:** Le service backend n'est pas prêt

**Solution:**
```bash
# Vérifier les pods
kubectl get pods -n cloudshop-prod

# Vérifier les services
kubectl get svc -n cloudshop-prod

# Logs du service
kubectl logs deployment/frontend -n cloudshop-prod
```

### Problème : "404 Not Found"

**Cause:** Le path ne correspond pas

**Solution:**
```bash
# Vérifier les routes de l'Ingress
kubectl describe ingress cloudshop-ingress -n cloudshop-prod

# Vérifier que les services existent
kubectl get svc frontend api-gateway -n cloudshop-prod
```

### Problème : Pas d'accès depuis Internet

**Cause:** Firewall du VPS bloque le port

**Solution:**
```bash
# Ouvrir les ports sur le VPS (exemple Ubuntu/UFW)
sudo ufw allow 30080/tcp
sudo ufw allow 30443/tcp
sudo ufw reload

# Ou pour iptables
sudo iptables -A INPUT -p tcp --dport 30080 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 30443 -j ACCEPT
sudo iptables-save
```

### Problème : Controller ne démarre pas

**Cause:** Ressources insuffisantes

**Solution:**
```bash
# Vérifier les events
kubectl get events -n ingress-nginx --sort-by='.lastTimestamp'

# Réduire les ressources si nécessaire
kubectl edit deployment ingress-nginx-controller -n ingress-nginx
```

### Problème : "default backend - 404"

**Cause:** Aucune route ne correspond

**Solution:** Vérifier votre configuration Ingress et le header `Host`

```bash
# Test avec le bon header Host
curl -H "Host: cloudshop.example.com" http://VPS_IP:30080/
```

---

## 📊 Monitoring

### Logs en temps réel

```bash
# Logs du controller
kubectl logs -f -n ingress-nginx -l app.kubernetes.io/component=controller

# Métriques
kubectl top pods -n ingress-nginx
```

### Prometheus Metrics

Le controller expose des métriques sur le port 10254 :
```bash
kubectl port-forward -n ingress-nginx svc/ingress-nginx-controller-metrics 10254:10254
curl http://localhost:10254/metrics
```

---

## 🎯 Intégration avec le Workflow CD

Le workflow CD applique automatiquement l'Ingress :

```yaml
# Dans .github/workflows/deploy.yml
kubectl apply -f k8s/ingress/
```

Pour utiliser l'Ingress VPS par défaut, renommez :

```bash
mv k8s/ingress/ingress.yaml k8s/ingress/ingress.yaml.bak
mv k8s/ingress/ingress-vps.yaml k8s/ingress/ingress.yaml
```

Ou modifiez le workflow pour choisir le bon fichier.

---

## 📝 Résumé des Commandes

```bash
# Installation
./scripts/install-ingress.sh

# Vérification
kubectl get pods -n ingress-nginx
kubectl get svc ingress-nginx-controller -n ingress-nginx
kubectl get ingress -n cloudshop-prod

# Application
kubectl apply -f k8s/ingress/ingress-vps.yaml

# Test
curl http://VPS_IP:30080/

# Debug
kubectl describe ingress cloudshop-ingress -n cloudshop-prod
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller

# Ouvrir les ports firewall
sudo ufw allow 30080/tcp
sudo ufw allow 30443/tcp
```

---

## 🔗 Ressources Utiles

- [NGINX Ingress Controller Documentation](https://kubernetes.github.io/ingress-nginx/)
- [Ingress Kubernetes Documentation](https://kubernetes.io/docs/concepts/services-networking/ingress/)
- [NGINX Ingress Annotations](https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/annotations/)

---

**Créé le:** 23 février 2026  
**Projet:** CloudShop CI/CD
