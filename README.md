# 🚀 Ansible Proxmox Infrastructure Automation

Automatisation complète du déploiement d'une infrastructure de VMs sur serveur Proxmox dédié Hetzner.

## ⚡ Démarrage Ultra-Rapide

```bash
# 1. Cloner le projet
git clone <repo-url>
cd ansible-proxmox-baremetal

# 2. Configurer les secrets
cp secret_vars.example.yml secret_vars.yml
# Éditer secret_vars.yml avec tes informations

# 3. Créer toutes les VMs
./run_automation.sh

# 4. Se connecter aux VMs
ssh -J root@167.235.118.227 imane@167.235.118.228  # proxy-vm
```

## 🏗️ Architecture Déployée

```
Internet → Serveur Hetzner (167.235.118.227)
    ↓
Proxmox VE - Interface Web: https://167.235.118.227:8006
    ↓
4 VMs automatiquement créées:
├─ proxy-vm (167.235.118.228) - Jump Host public
└─ Réseau privé (10.0.1.x/24):
   ├─ frontend-vm (10.0.1.10)
   ├─ backend-vm (10.0.1.20)
   └─ database-vm (10.0.1.30)
```

## 📋 Scripts Principaux

| Script | Description |
|--------|-------------|
| `./run_automation.sh` | 🚀 Créer toutes les VMs automatiquement |
| `./check_automation.sh` | ✅ Vérifier l'état des VMs |
| `./cleanup_automation.sh` | 🧹 Supprimer toutes les VMs |

## 📚 Documentation Complète

**Guides Essentiels :**
- **[Documentation Complète](./docs/README.md)** - Point d'entrée principal
- **[Guide SSH](./docs/ssh_connection_guide.md)** - Se connecter aux VMs
- **[Architecture](./docs/deployment_architecture.md)** - Schéma détaillé

## 🔧 Prérequis

- Serveur Proxmox installé sur Hetzner
- Python 3 avec `proxmoxer` installé
- Ansible avec collection `community.proxmox`
- Accès SSH configuré vers Proxmox

## ⚙️ Configuration

**1. Secrets :**
```bash
cp secret_vars.example.yml secret_vars.yml
# Éditer avec tes identifiants Proxmox
```

**2. Configuration VM :**
```bash
cp vm_config.example.yml vm_config.yml  
# Ajuster si nécessaire
```

## 🛠️ Utilisation Avancée

**Créer une VM spécifique :**
```bash
ansible-playbook playbooks/create_vms_ssh.yml -e vm_config=examples/vm-frontend.yml
```

**Tester la connectivité :**
```bash
ansible-playbook playbooks/test_connection.yml
```

## 📁 Structure du Projet

```
ansible-proxmox-baremetal/
├── docs/                    # 📚 Documentation complète
│   ├── README.md           # Point d'entrée documentation
│   ├── ssh_connection_guide.md
│   └── deployment_architecture.md
├── playbooks/              # 🎭 Playbooks Ansible
│   ├── create_vms_ssh.yml  # Création VMs
│   ├── cleanup_vms.yml     # Nettoyage
│   └── test_connection.yml # Tests
├── examples/               # 📝 Exemples config VMs
│   ├── vm-proxy.yml
│   ├── vm-frontend.yml
│   ├── vm-backend.yml
│   └── vm-database.yml
├── run_automation.sh       # ▶️ Script principal
├── cleanup_automation.sh   # 🧹 Nettoyage
├── check_automation.sh     # ✅ Vérification
├── secret_vars.yml         # 🔐 Secrets (à créer)
└── vm_config.example.yml   # ⚙️ Config exemple
```

## 🎯 Cas d'Usage

- **Développement** : Infrastructure de test rapide
- **Staging** : Environnement de pré-production
- **Production** : Base pour infrastructure sécurisée
- **Formation** : Apprendre Proxmox et Ansible

## 📞 Support & Dépannage

- **Problèmes SSH** → `docs/ssh_connection_guide.md`
- **Architecture réseau** → `docs/deployment_architecture.md`
- **Configuration initiale** → `docs/network_configuration.md`

---

**🎉 Prêt en 3 minutes ! Automatisation complète de ton infrastructure Proxmox.**

