.PHONY: help build push deploy update-k8s health-check trivy-scan check-sizes

# Couleurs
GREEN = \033[0;32m
YELLOW = \033[1;33m
NC = \033[0m

help: ## Affiche cette aide
	@echo "$(GREEN)CloudShop - Commandes Disponibles:$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(GREEN)Variables d'environnement requises:$(NC)"
	@echo "  DOCKER_USERNAME - Votre nom d'utilisateur DockerHub"
	@echo "  VPS_HOST - IP ou domaine de votre VPS"
	@echo "  VPS_USER - Utilisateur SSH (défaut: root)"
	@echo ""
	@echo "$(GREEN)Exemple:$(NC)"
	@echo "  export DOCKER_USERNAME=myusername"
	@echo "  export VPS_HOST=192.168.1.100"
	@echo "  make deploy"

update-k8s: ## Met à jour les manifests K8s avec votre DOCKER_USERNAME
	@if [ -z "$(DOCKER_USERNAME)" ]; then \
		echo "$(RED)Erreur: DOCKER_USERNAME n'est pas défini$(NC)"; \
		echo "Utilisez: export DOCKER_USERNAME=your_username"; \
		exit 1; \
	fi
	@./scripts/update-k8s-images.sh $(DOCKER_USERNAME)

build: ## Build toutes les images Docker
	@./scripts/deploy.sh --build-only

push: ## Push toutes les images sur DockerHub
	@./scripts/deploy.sh --push-only

deploy-vps: ## Deploy sur le VPS uniquement
	@./scripts/deploy.sh --deploy-only

deploy: ## Build, push et deploy (complet)
	@./scripts/deploy.sh

health-check: ## Vérifie la santé des services
	@./scripts/health-check.sh

trivy-scan: ## Scan de sécurité avec Trivy
	@./scripts/trivy-scan.sh

check-sizes: ## Vérifie la taille des images
	@./scripts/check-image-sizes.sh

docker-compose-up: ## Lance l'application en local avec Docker Compose
	docker-compose up -d

docker-compose-down: ## Arrête l'application en local
	docker-compose down

docker-compose-logs: ## Affiche les logs Docker Compose
	docker-compose logs -f

k8s-apply: ## Applique les manifests Kubernetes
	kubectl apply -f k8s/namespaces/
	kubectl apply -f k8s/configs/
	kubectl apply -f k8s/statefulsets/
	kubectl apply -f k8s/deployments/
	kubectl apply -f k8s/services/
	kubectl apply -f k8s/ingress/

k8s-delete: ## Supprime les ressources Kubernetes
	kubectl delete -f k8s/ingress/ --ignore-not-found=true
	kubectl delete -f k8s/services/ --ignore-not-found=true
	kubectl delete -f k8s/deployments/ --ignore-not-found=true
	kubectl delete -f k8s/statefulsets/ --ignore-not-found=true
	kubectl delete -f k8s/configs/ --ignore-not-found=true
	kubectl delete -f k8s/namespaces/ --ignore-not-found=true

k8s-status: ## Affiche le status des ressources K8s
	@echo "$(GREEN)Namespaces:$(NC)"
	@kubectl get namespaces | grep cloudshop || true
	@echo ""
	@echo "$(GREEN)Deployments:$(NC)"
	@kubectl get deployments -n cloudshop-prod
	@echo ""
	@echo "$(GREEN)Pods:$(NC)"
	@kubectl get pods -n cloudshop-prod
	@echo ""
	@echo "$(GREEN)Services:$(NC)"
	@kubectl get services -n cloudshop-prod

k8s-logs: ## Affiche les logs d'un service K8s (usage: make k8s-logs SERVICE=frontend)
	@if [ -z "$(SERVICE)" ]; then \
		echo "$(RED)Erreur: SERVICE n'est pas défini$(NC)"; \
		echo "Utilisez: make k8s-logs SERVICE=frontend"; \
		exit 1; \
	fi
	kubectl logs -f deployment/$(SERVICE) -n cloudshop-prod

k8s-restart: ## Redémarre tous les déploiements K8s
	kubectl rollout restart deployment/frontend -n cloudshop-prod
	kubectl rollout restart deployment/api-gateway -n cloudshop-prod
	kubectl rollout restart deployment/auth-service -n cloudshop-prod
	kubectl rollout restart deployment/orders-api -n cloudshop-prod
	kubectl rollout restart deployment/products-api -n cloudshop-prod

clean: ## Nettoie les images Docker locales
	@echo "$(YELLOW)Nettoyage des images Docker...$(NC)"
	docker image prune -f
	docker container prune -f

clean-all: ## Nettoie tout (images, containers, volumes)
	@echo "$(YELLOW)Nettoyage complet...$(NC)"
	docker system prune -a -f --volumes

init: ## Configuration initiale du projet
	@echo "$(GREEN)🚀 Configuration initiale de CloudShop$(NC)"
	@echo ""
	@echo "1. Entrez votre nom d'utilisateur DockerHub:"
	@read -p "DOCKER_USERNAME: " username; \
	./scripts/update-k8s-images.sh $$username
	@echo ""
	@echo "$(GREEN)✅ Configuration terminée!$(NC)"
	@echo ""
	@echo "$(YELLOW)Prochaines étapes:$(NC)"
	@echo "1. Configurez les secrets GitHub (voir DEPLOYMENT.md)"
	@echo "2. Committez les changements: git add k8s/ && git commit -m 'Configure Docker images'"
	@echo "3. Push pour déployer: git push"
