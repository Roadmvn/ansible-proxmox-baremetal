# Ansible Proxmox Baremetal Automation

Ce projet contient un ensemble de playbooks et de scripts Ansible pour automatiser le déploiement de machines virtuelles (VMs) sur un serveur baremetal Proxmox chez Hetzner.

## 🚀 Objectif

L'objectif est de fournir une méthode rapide et reproductible pour créer une architecture de VMs comprenant :
- Une VM publique (Proxy/Bastion)
- Trois VMs privées (Frontend, Backend, Database)

## 📁 Structure du projet

```
.
├── ansible.cfg
├── check_automation.sh
├── cleanup_automation.sh
├── docs
│   ├── README.md
│   ├── deployment_architecture.md
│   └── network_configuration.md
├── examples
│   ├── README.md
│   ├── vm-backend.yml
│   ├── vm-database.yml
│   ├── vm-frontend.yml
│   └── vm-proxy.yml
├── hosts
├── playbooks
│   ├── cleanup_vms.yml
│   ├── create_vms_ssh.yml
│   ├── tasks
│   │   └── create_single_vm.yml
│   └── test_connection.yml
├── README.md
├── run_automation.sh
├── secret_vars.yml
└── vm_config.example.yml
```

## 🛠️ Prérequis

1. **Ansible installé** sur votre machine de contrôle.
2. **Accès SSH** configuré à votre serveur Proxmox (via clé SSH recommandée).
3. Un **template Cloud-Init Ubuntu** prêt sur Proxmox (par exemple, `ubuntu-2204-cloudinit-template`).
4. **Fichier d'inventaire `hosts`** configuré avec l'IP de votre serveur Proxmox.
5. **Fichier `secret_vars.yml`** créé avec vos identifiants (non suivi par Git).

## ⚙️ Configuration

1. **Cloner le projet** :
   ```bash
   git clone <URL_DU_REPO>
   cd ansible-proxmox-baremetal
   ```

2. **Configurer l'inventaire (`hosts`)** :
   ```ini
   [proxmox]
   <IP_PROXMOX> ansible_user=root
   ```

3. **Configurer les variables sensibles (`secret_vars.yml`)** :
   Créez un fichier `secret_vars.yml` à la racine et ajoutez vos identifiants. Ce fichier est ignoré par Git pour des raisons de sécurité.

4. **Adapter la configuration des VMs (`vm_config.example.yml`)** :
   Modifiez ce fichier pour ajuster les ressources (CPU, RAM, disque) ou les adresses IP selon vos besoins.

## 🚀 Utilisation

Les scripts suivants simplifient l'utilisation des playbooks :

- **Créer toutes les VMs** :
  ```bash
  ./run_automation.sh
  ```

- **Vérifier l'état et la connectivité** :
  ```bash
  ./check_automation.sh
  ```

- **Supprimer toutes les VMs** :
  ```bash
  ./cleanup_automation.sh
  ```

## 📚 Documentation détaillée

- **[Architecture de déploiement](./docs/deployment_architecture.md)**
- **[Configuration réseau](./docs/network_configuration.md)**
- **[Guide post-création](./docs/post_creation_guide.md)**

