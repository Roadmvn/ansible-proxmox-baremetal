# Infrastructure as Code

Automatisation complete : Proxmox + Kubernetes + Applications.

## Structure

```
ig-infra-as-code/
├── ansible/          # Proxmox + Kubernetes (Kubespray)
├── terraform/        # Infrastructure S3
└── kubernetes/       # Applications K8s (manifests)
```

## Quick Start

```bash
cd ansible

# 1. Proxmox
make proxmox-install              # Installer Proxmox VE
make proxmox-cluster              # Creer le cluster

# 2. Kubernetes
make k8s-setup                    # Installer Kubespray
make k8s-cluster K8S_ENV=production   # Deployer K8s
make k8s-kubeconfig K8S_ENV=production

# 3. Applications
cd ../kubernetes
export KUBECONFIG=~/.kube/config-production
make apps-gophish                 # Deployer GoPhish
```

## Commandes Ansible

```bash
cd ansible && make help

# Proxmox
make proxmox-install-test         # Test SSH
make proxmox-install              # Installer Proxmox
make proxmox-cluster              # Creer cluster
make proxmox-cluster-health       # Verifier sante

# Kubernetes
make k8s-setup                    # Clone Kubespray
make k8s-test                     # Test SSH nodes
make k8s-cluster                  # Deployer cluster
make k8s-scale                    # Ajouter nodes
make k8s-reset                    # Detruire cluster
```

## Commandes Kubernetes

```bash
cd kubernetes && make help

make apps-gophish                 # Deployer GoPhish
make apps-gophish-delete          # Supprimer GoPhish
make status                       # Statut des apps
```

## Configuration

### Proxmox

Editer `ansible/inventory/proxmox/install.yml` et `cluster.yml` avec vos IPs.

### Kubernetes

```bash
# Copier et adapter l'inventaire
cp -r ansible/inventory/kubernetes/sample ansible/inventory/kubernetes/production
nano ansible/inventory/kubernetes/production/hosts.yml
```

### Applications

```bash
# Modifier les secrets et domaines avant deploiement
nano kubernetes/apps/gophish/overlays/production/secrets-patch.yml
nano kubernetes/apps/gophish/overlays/production/ingress.yml
```

## Prerequis

- Ansible >= 2.14
- Terraform >= 1.0
- Python 3
- Acces SSH root aux serveurs

## Licence

MIT
