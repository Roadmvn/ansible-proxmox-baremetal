# 📚 Documentation - Proxmox Infrastructure Automation

## 🎯 Vue d'Ensemble

Cette documentation couvre l'automatisation complète d'une infrastructure Proxmox sur serveur dédié Hetzner, de l'installation initiale au déploiement d'applications.

---

## 📋 Guide de Navigation

### 🚀 **Démarrage Rapide**
- **[Architecture & Réseau](./deployment_architecture.md)** - Comprendre l'infrastructure complète
- **[Guide SSH](./ssh_connection_guide.md)** - Se connecter aux VMs internes

### 🔧 **Configuration & Déploiement**  
- **[Configuration Réseau](./network_configuration.md)** - Ponts vmbr0/vmbr1 et plan IP
- **[Post-Création](./post_creation_guide.md)** - Étapes après création des VMs

### 🛠️ **Guides Spécialisés**
- **[Création VM](./vm_creation_guide.md)** - Processus détaillé de création VM
- **[Mode Rescue Hetzner](./rescue_mode_hetzner.md)** - Installation Proxmox from scratch
- **[VM Runner](./vm_runner_deployment.md)** - Déploiement avec GitHub Actions

---

## 🗂️ Organisation du Projet

```
ansible-proxmox-baremetal/
├── docs/                    # 📚 Documentation complète
├── playbooks/              # 🎭 Playbooks Ansible
├── examples/               # 📝 Exemples de configuration VM
├── run_automation.sh       # ▶️ Script principal d'automatisation
├── cleanup_automation.sh   # 🧹 Nettoyage des VMs
└── check_automation.sh     # ✅ Vérification de l'état
```

---

## 🎪 Architecture Simplifiée

```
Internet → Serveur Hetzner (167.235.118.227)
    ↓
Proxmox (PVE) - Interface: https://167.235.118.227:8006
    ↓
📍 VMs sur 2 réseaux:
   ├─ vmbr0 (167.235.118.x/26) - proxy-vm
   └─ vmbr1 (10.0.1.x/24) - frontend, backend, database
```

---

## 🚀 Démarrage Ultra-Rapide

**1. Créer toutes les VMs :**
```bash
./run_automation.sh
```

**2. Se connecter aux VMs :**
```bash
# Via jump host automatique
ssh -J root@167.235.118.227 imane@167.235.118.228  # proxy-vm
ssh -J root@167.235.118.227,imane@167.235.118.228 imane@10.0.1.10  # frontend-vm
```

**3. Nettoyer (si besoin) :**
```bash
./cleanup_automation.sh
```

---

## 📞 Support

- **Architecture réseau** → `deployment_architecture.md`
- **Problèmes SSH** → `ssh_connection_guide.md`  
- **Configuration initiale** → `network_configuration.md`
- **Dépannage VMs** → `post_creation_guide.md` 