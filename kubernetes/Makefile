# ============================================
# Makefile - Applications Kubernetes
# ============================================

.PHONY: help apps-all apps-gophish apps-gophish-delete apps-plane apps-plane-delete kubeconfig

# Couleurs
GREEN  := \033[0;32m
YELLOW := \033[1;33m
RED    := \033[0;31m
NC     := \033[0m

# Variables
KUBECONFIG ?= ~/.kube/config

help: ## Afficher l'aide
	@echo "$(GREEN)════════════════════════════════════════════════════════════$(NC)"
	@echo "$(GREEN)  Applications Kubernetes$(NC)"
	@echo "$(GREEN)════════════════════════════════════════════════════════════$(NC)"
	@echo ""
	@echo "$(GREEN)Prerequis :$(NC)"
	@echo "  1. Deployer le cluster K8s:  cd ../ansible && make k8s-cluster"
	@echo "  2. Configurer kubeconfig:    cd ../ansible && make k8s-kubeconfig"
	@echo "  3. Exporter KUBECONFIG:      export KUBECONFIG=~/.kube/config-production"
	@echo ""
	@echo "$(GREEN)Applications :$(NC)"
	@echo "  $(YELLOW)make apps-gophish$(NC)         Deployer GoPhish"
	@echo "  $(YELLOW)make apps-gophish-delete$(NC)  Supprimer GoPhish"
	@echo "  $(YELLOW)make apps-plane$(NC)           Deployer Plane"
	@echo "  $(YELLOW)make apps-plane-delete$(NC)    Supprimer Plane"
	@echo "  $(YELLOW)make apps-all$(NC)             Deployer toutes les apps"
	@echo ""
	@echo "$(GREEN)Utilitaires :$(NC)"
	@echo "  $(YELLOW)make check$(NC)                Verifier connexion cluster"
	@echo "  $(YELLOW)make status$(NC)               Statut des apps deployees"

# ============================================
# VERIFICATION
# ============================================

check: ## Verifier la connexion au cluster
	@echo "$(GREEN)Verification de la connexion au cluster...$(NC)"
	@kubectl cluster-info || (echo "$(RED)Erreur: Impossible de se connecter au cluster$(NC)" && exit 1)
	@kubectl get nodes

status: ## Afficher le statut des applications
	@echo "$(GREEN)Statut des applications...$(NC)"
	@echo ""
	@echo "$(YELLOW)=== Namespaces ===$(NC)"
	@kubectl get ns | grep -E "gophish|plane" || echo "Aucune app deployee"
	@echo ""
	@echo "$(YELLOW)=== Pods ===$(NC)"
	@kubectl get pods -A | grep -E "gophish|plane" || echo "Aucun pod"
	@echo ""
	@echo "$(YELLOW)=== Services ===$(NC)"
	@kubectl get svc -A | grep -E "gophish|plane" || echo "Aucun service"

# ============================================
# GOPHISH
# ============================================

apps-gophish: ## Deployer GoPhish
	@echo "$(GREEN)Deploiement de GoPhish...$(NC)"
	@echo "$(YELLOW)N'oubliez pas de modifier les secrets et l'ingress !$(NC)"
	kubectl apply -k apps/gophish/overlays/production
	@echo "$(GREEN)GoPhish deploye !$(NC)"

apps-gophish-delete: ## Supprimer GoPhish
	@echo "$(YELLOW)Suppression de GoPhish...$(NC)"
	kubectl delete -k apps/gophish/overlays/production --ignore-not-found
	@echo "$(GREEN)GoPhish supprime$(NC)"

apps-gophish-logs: ## Voir les logs GoPhish
	kubectl logs -n gophish -l app=gophish --tail=100 -f

# ============================================
# PLANE (Helm)
# ============================================

apps-plane-setup: ## Ajouter le repo Helm Plane
	@echo "$(GREEN)Configuration du repo Helm Plane...$(NC)"
	helm repo add makeplane https://helm.plane.so || true
	helm repo update

apps-plane: apps-plane-setup ## Deployer Plane via Helm
	@echo "$(GREEN)Deploiement de Plane...$(NC)"
	@echo "$(YELLOW)N'oubliez pas de modifier apps/plane/overlays/production/values.yml !$(NC)"
	kubectl apply -f apps/plane/base/namespace.yml
	helm upgrade --install plane makeplane/plane-ce \
		-n plane \
		-f apps/plane/overlays/production/values.yml \
		--timeout 10m \
		--wait
	@echo "$(GREEN)Plane deploye !$(NC)"

apps-plane-delete: ## Supprimer Plane
	@echo "$(YELLOW)Suppression de Plane...$(NC)"
	helm uninstall plane -n plane --ignore-not-found || true
	kubectl delete ns plane --ignore-not-found
	@echo "$(GREEN)Plane supprime$(NC)"

# ============================================
# ALL APPS
# ============================================

apps-all: apps-gophish apps-plane ## Deployer toutes les applications
	@echo "$(GREEN)Toutes les applications deployees !$(NC)"

apps-all-delete: apps-gophish-delete apps-plane-delete ## Supprimer toutes les applications
	@echo "$(GREEN)Toutes les applications supprimees$(NC)"
