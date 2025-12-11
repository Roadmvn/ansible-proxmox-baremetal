# ============================================
# Makefile - Ansible (Proxmox + Kubernetes)
# ============================================

.PHONY: help test deploy deploy-one deploy-test update backup check setup clean \
        proxmox-install proxmox-install-one proxmox-install-test proxmox-cluster proxmox-cluster-test proxmox-cluster-destroy proxmox-cluster-status proxmox-cluster-health \
        k8s-setup k8s-cluster k8s-scale k8s-reset k8s-upgrade k8s-test k8s-kubeconfig

# Couleurs
GREEN  := \033[0;32m
YELLOW := \033[1;33m
RED    := \033[0;31m
NC     := \033[0m

# Variables
K8S_ENV ?= sample
KUBESPRAY_VERSION ?= v2.24.0

help: ## Afficher l'aide
	@echo "$(GREEN)════════════════════════════════════════════════════════════$(NC)"
	@echo "$(GREEN)  Ansible - Proxmox & Kubernetes$(NC)"
	@echo "$(GREEN)════════════════════════════════════════════════════════════$(NC)"
	@echo ""
	@echo "$(GREEN)Proxmox VE - Installation :$(NC)"
	@echo "  $(YELLOW)make proxmox-install-test$(NC)      Tester connectivite"
	@echo "  $(YELLOW)make proxmox-install$(NC)           Installer Proxmox sur tous les VPS"
	@echo "  $(YELLOW)make proxmox-install-one NODE=x$(NC) Installer sur 1 VPS"
	@echo ""
	@echo "$(GREEN)Proxmox VE - Cluster :$(NC)"
	@echo "  $(YELLOW)make proxmox-cluster-test$(NC)      Tester connectivite cluster"
	@echo "  $(YELLOW)make proxmox-cluster$(NC)           Creer le cluster"
	@echo "  $(YELLOW)make proxmox-cluster-destroy$(NC)   Detruire le cluster"
	@echo "  $(YELLOW)make proxmox-cluster-status$(NC)    Statut du cluster"
	@echo "  $(YELLOW)make proxmox-cluster-health$(NC)    Sante du cluster"
	@echo ""
	@echo "$(GREEN)Kubernetes :$(NC)"
	@echo "  $(YELLOW)make k8s-setup$(NC)                 Installer Kubespray"
	@echo "  $(YELLOW)make k8s-test$(NC)                  Tester connectivite nodes"
	@echo "  $(YELLOW)make k8s-cluster$(NC)               Deployer le cluster K8s"
	@echo "  $(YELLOW)make k8s-scale$(NC)                 Ajouter des nodes"
	@echo "  $(YELLOW)make k8s-upgrade$(NC)               Upgrader Kubernetes"
	@echo "  $(YELLOW)make k8s-reset$(NC)                 Detruire le cluster"
	@echo "  $(YELLOW)make k8s-kubeconfig$(NC)            Recuperer kubeconfig"
	@echo ""
	@echo "$(GREEN)Options :$(NC)"
	@echo "  K8S_ENV=sample|production        Environnement K8s (defaut: sample)"

test: ## Tester la connectivité Ansible vers tous les nœuds
	@echo "$(GREEN)Test de connectivité...$(NC)"
	ansible all -m ping

test-node: ## Tester un nœud spécifique (usage: make test-node NODE=node1)
	@echo "$(GREEN)Test de connectivité vers $(NODE)...$(NC)"
	ansible $(NODE) -m ping

deploy: ## Déployer sur tous les nœuds (production)
	@echo "$(GREEN)Déploiement sur tous les nœuds...$(NC)"
	ansible-playbook playbooks/deploy.yml

deploy-test: ## Déployer sur le nœud de test uniquement
	@echo "$(GREEN)Déploiement sur nœud test...$(NC)"
	ansible-playbook -i inventory/test.ini playbooks/deploy.yml

deploy-one: ## Déployer sur un nœud spécifique (usage: make deploy-one NODE=node1)
	@echo "$(GREEN)Déploiement sur $(NODE)...$(NC)"
	ansible-playbook playbooks/deploy.yml --limit $(NODE)

deploy-dry: ## Simulation de déploiement (dry-run)
	@echo "$(YELLOW)Simulation de déploiement...$(NC)"
	ansible-playbook playbooks/deploy.yml --check --diff

update: ## Mettre à jour les scripts sur tous les nœuds
	@echo "$(GREEN)Mise à jour...$(NC)"
	ansible-playbook playbooks/update.yml

backup: ## Lancer un backup maintenant sur tous les nœuds
	@echo "$(GREEN)Lancement du backup...$(NC)"
	ansible-playbook playbooks/backup-now.yml

backup-one: ## Lancer backup sur un nœud (usage: make backup-one NODE=node1)
	@echo "$(GREEN)Lancement du backup sur $(NODE)...$(NC)"
	ansible-playbook playbooks/backup-now.yml --limit $(NODE)

check: ## Vérifier la configuration avant déploiement
	@echo "$(GREEN)Vérification de la configuration...$(NC)"
	./scripts/check.sh

setup: ## Configuration interactive initiale
	@echo "$(GREEN)Configuration interactive...$(NC)"
	./scripts/setup.sh

health: ## Vérifier la santé des systèmes déployés
	@echo "$(GREEN)Vérification santé système...$(NC)"
	ansible-playbook playbooks/health-check.yml

list: ## Lister les backups disponibles
	@echo "$(GREEN)Liste des backups...$(NC)"
	ansible all -m shell -a "/opt/ansible-proxmox/scripts/proxmox-backup/list-backups.sh"

logs: ## Afficher les derniers logs (usage: make logs NODE=node1)
	@echo "$(GREEN)Derniers logs de $(NODE)...$(NC)"
	ansible $(NODE) -m shell -a "tail -50 /var/log/proxmox-backup/$(NODE)-$$(date +%Y-%m-%d).log"

clean: ## Nettoyer les fichiers temporaires Ansible
	@echo "$(YELLOW)Nettoyage...$(NC)"
	find . -name "*.retry" -delete
	find . -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
	@echo "$(GREEN)Nettoyage terminé$(NC)"

version: ## Afficher les versions
	@echo "$(GREEN)Versions :$(NC)"
	@echo "Ansible: $$(ansible --version | head -1)"
	@echo "Python: $$(python3 --version)"

# ============================================
# PROXMOX VE - INSTALLATION
# ============================================

proxmox-install-test: ## Tester la connectivite vers les VPS Proxmox
	@echo "$(GREEN)Test de connectivite vers les VPS Proxmox...$(NC)"
	ansible -i inventory/proxmox/install.yml proxmox_install -m ping

proxmox-install: ## Installer Proxmox VE sur tous les VPS
	@echo "$(GREEN)Installation de Proxmox VE sur tous les VPS...$(NC)"
	@echo "$(YELLOW)Cette operation va redemarrer les serveurs !$(NC)"
	@read -p "Continuer ? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		ansible-playbook -i inventory/proxmox/install.yml playbooks/install-proxmox-official.yml; \
	else \
		echo "$(YELLOW)Installation annulee$(NC)"; \
	fi

proxmox-install-one: ## Installer Proxmox sur un VPS (usage: make proxmox-install-one NODE=pve1)
	@echo "$(GREEN)Installation de Proxmox VE sur $(NODE)...$(NC)"
	@echo "$(YELLOW)Cette operation va redemarrer le serveur !$(NC)"
	@read -p "Continuer ? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		ansible-playbook -i inventory/proxmox/install.yml playbooks/install-proxmox-official.yml --limit $(NODE); \
	else \
		echo "$(YELLOW)Installation annulee$(NC)"; \
	fi

proxmox-install-dry: ## Simulation installation Proxmox (dry-run)
	@echo "$(YELLOW)Simulation installation Proxmox VE...$(NC)"
	ansible-playbook -i inventory/proxmox/install.yml playbooks/install-proxmox-official.yml --check --diff

# ============================================
# PROXMOX VE - CLUSTER
# ============================================

proxmox-cluster-test: ## Tester la connectivite vers les noeuds du cluster
	@echo "$(GREEN)Test de connectivite vers les noeuds du cluster...$(NC)"
	ansible -i inventory/proxmox/cluster.yml proxmox_cluster -m ping

proxmox-cluster: ## Creer un cluster Proxmox VE
	@echo "$(GREEN)Creation du cluster Proxmox VE...$(NC)"
	@echo "$(YELLOW)Cette operation va creer un cluster !$(NC)"
	@read -p "Continuer ? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		ansible-playbook -i inventory/proxmox/cluster.yml playbooks/create-proxmox-cluster.yml; \
	else \
		echo "$(YELLOW)Creation annulee$(NC)"; \
	fi

proxmox-cluster-dry: ## Simulation creation cluster (dry-run)
	@echo "$(YELLOW)Simulation creation cluster Proxmox VE...$(NC)"
	ansible-playbook -i inventory/proxmox/cluster.yml playbooks/create-proxmox-cluster.yml --check --diff

proxmox-cluster-destroy: ## Detruire le cluster Proxmox VE
	@echo "$(RED)ATTENTION : Cette operation va detruire le cluster !$(NC)"
	@read -p "Tapez 'destroy' pour confirmer: " confirm; \
	if [ "$$confirm" = "destroy" ]; then \
		ansible-playbook -i inventory/proxmox/cluster.yml playbooks/destroy-proxmox-cluster.yml; \
	else \
		echo "$(YELLOW)Destruction annulee$(NC)"; \
	fi

proxmox-cluster-status: ## Afficher le statut du cluster
	@echo "$(GREEN)Statut du cluster Proxmox VE...$(NC)"
	ansible -i inventory/proxmox/cluster.yml proxmox_cluster -m shell -a "pvecm status" -b

proxmox-cluster-health: ## Verifier la sante du cluster
	@echo "$(GREEN)Verification de la sante du cluster...$(NC)"
	@ansible -i inventory/proxmox/cluster.yml proxmox_cluster_primary -m shell -a "pvecm status" -b | grep -v ">>>"
	@ansible -i inventory/proxmox/cluster.yml proxmox_cluster_primary -m shell -a "pvecm nodes" -b | grep -v ">>>"

# ============================================
# KUBERNETES
# ============================================

k8s-setup: ## Installer Kubespray (clone le repo)
	@echo "$(GREEN)Installation de Kubespray $(KUBESPRAY_VERSION)...$(NC)"
	@if [ ! -d "vendor/kubespray" ]; then \
		git clone --depth 1 --branch $(KUBESPRAY_VERSION) https://github.com/kubernetes-sigs/kubespray.git vendor/kubespray; \
		pip3 install -r vendor/kubespray/requirements.txt; \
		echo "$(GREEN)Kubespray installe !$(NC)"; \
	else \
		echo "$(YELLOW)Kubespray deja installe$(NC)"; \
	fi

k8s-test: ## Tester la connectivite vers les nodes K8s
	@echo "$(GREEN)Test de connectivite vers les nodes Kubernetes...$(NC)"
	ansible -i inventory/kubernetes/$(K8S_ENV)/hosts.yml all -m ping

k8s-cluster: ## Deployer le cluster Kubernetes
	@echo "$(GREEN)Deploiement du cluster Kubernetes...$(NC)"
	@echo "$(YELLOW)Environnement: $(K8S_ENV)$(NC)"
	@if [ ! -d "vendor/kubespray" ]; then \
		echo "$(RED)Erreur: Kubespray non installe. Lancez 'make k8s-setup' d'abord$(NC)"; \
		exit 1; \
	fi
	@read -p "Continuer ? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		ansible-playbook -i inventory/kubernetes/$(K8S_ENV)/hosts.yml vendor/kubespray/cluster.yml; \
	fi

k8s-cluster-dry: ## Simulation deploiement K8s (dry-run)
	@echo "$(YELLOW)Simulation deploiement Kubernetes...$(NC)"
	ansible-playbook -i inventory/kubernetes/$(K8S_ENV)/hosts.yml vendor/kubespray/cluster.yml --check --diff

k8s-scale: ## Ajouter des nodes au cluster
	@echo "$(GREEN)Ajout de nodes au cluster Kubernetes...$(NC)"
	ansible-playbook -i inventory/kubernetes/$(K8S_ENV)/hosts.yml vendor/kubespray/scale.yml

k8s-upgrade: ## Upgrader le cluster Kubernetes
	@echo "$(GREEN)Upgrade du cluster Kubernetes...$(NC)"
	@read -p "Continuer ? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		ansible-playbook -i inventory/kubernetes/$(K8S_ENV)/hosts.yml vendor/kubespray/upgrade-cluster.yml; \
	fi

k8s-reset: ## Detruire le cluster Kubernetes
	@echo "$(RED)ATTENTION : Cette operation va detruire le cluster K8s !$(NC)"
	@read -p "Tapez 'destroy' pour confirmer: " confirm; \
	if [ "$$confirm" = "destroy" ]; then \
		ansible-playbook -i inventory/kubernetes/$(K8S_ENV)/hosts.yml vendor/kubespray/reset.yml; \
	else \
		echo "$(YELLOW)Destruction annulee$(NC)"; \
	fi

k8s-kubeconfig: ## Recuperer le kubeconfig depuis le master
	@echo "$(GREEN)Recuperation du kubeconfig...$(NC)"
	@MASTER_IP=$$(grep -A1 "master1:" inventory/kubernetes/$(K8S_ENV)/hosts.yml | grep ansible_host | cut -d: -f2 | tr -d ' '); \
	mkdir -p ~/.kube; \
	scp root@$$MASTER_IP:/etc/kubernetes/admin.conf ~/.kube/config-$(K8S_ENV); \
	echo "$(GREEN)Kubeconfig sauve dans ~/.kube/config-$(K8S_ENV)$(NC)"; \
	echo "$(YELLOW)Usage: export KUBECONFIG=~/.kube/config-$(K8S_ENV)$(NC)"
