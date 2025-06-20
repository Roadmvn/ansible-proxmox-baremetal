# Déploiement de la VM Runner sur Proxmox

## Vue d'ensemble

Ce playbook Ansible automatise la création d'une machine virtuelle Debian 12 nommée "runner-vm" sur un cluster Proxmox. Cette VM est destinée à héberger des conteneurs Docker et servir de runner pour vos projets.

## Prérequis

### Infrastructure
- Proxmox VE 8.x fonctionnel (node unique nommé "pve")
- ISO Debian 12.5.0 téléchargée dans le stockage `local:iso/`
- Stockage `local-lvm` disponible avec au moins 20GB d'espace libre
- Bridge réseau `vmbr0` configuré

### Logiciels
- Ansible installé sur votre machine de contrôle
- Collection `community.general` installée :
  ```bash
  ansible-galaxy collection install community.general
  ```

## Configuration des variables

### Fichier `secret_vars.yml`
Assurez-vous que votre fichier `secret_vars.yml` contient au minimum :

```yaml
---
proxmox_host: "VOTRE_IP_PROXMOX"      # Ex: 167.235.118.227
proxmox_user: "root"                   # Utilisateur Proxmox
proxmox_password: "VOTRE_MOT_DE_PASSE" # Mot de passe root Proxmox
```

**⚠️ Sécurité :** En production, utilisez `ansible-vault` pour chiffrer ce fichier.

## Utilisation

### Exécution du playbook
```bash
cd /chemin/vers/votre/projet
ansible-playbook playbooks/vm_runner.yml --extra-vars "@secret_vars.yml"
```

### Avec Ansible Vault (recommandé pour la production)
```bash
# Chiffrer le fichier de variables
ansible-vault encrypt secret_vars.yml

# Exécuter le playbook
ansible-playbook playbooks/vm_runner.yml --extra-vars "@secret_vars.yml" --ask-vault-pass
```

## Spécifications de la VM

| Paramètre | Valeur |
|-----------|---------|
| **VMID** | 200 |
| **Nom** | runner-vm |
| **OS Type** | Linux 2.6+ (l26) |
| **CPU** | 2 cores |
| **RAM** | 2048 Mo (2 GB) |
| **Disque** | 20 GB (local-lvm, format raw) |
| **Réseau** | virtio sur bridge vmbr0 |
| **ISO** | debian-12.5.0-amd64-netinst.iso |
| **Boot** | CD-ROM puis disque |
| **Auto-start** | Activé |

## Fonctionnement du playbook

### Étape 1 : Création/Mise à jour de la VM
- **Idempotence** : Si la VM existe déjà, ses paramètres sont mis à jour sans destruction
- **Configuration** : Application de tous les paramètres spécifiés (CPU, RAM, disque, réseau)
- **ISO** : Montage automatique de l'ISO Debian dans le lecteur CD-ROM virtuel

### Étape 2 : Démarrage de la VM
- Démarre la VM uniquement si elle vient d'être créée ou modifiée
- Évite les redémarrages inutiles si la VM fonctionne déjà

### Étape 3 : Confirmation
- Affiche un message confirmant la réussite du déploiement
- Rappel d'installer manuellement Debian via l'interface Proxmox

## Résultat attendu

Après exécution réussie, vous devriez voir :

```
TASK [Message de confirmation] *************************************************
ok: [localhost] => {
    "msg": "VM runner-vm (#200) prête ! Pense à monter l'ISO et installer Debian."
}
```

La VM apparaîtra dans l'interface web Proxmox à l'adresse : `https://VOTRE_IP_PROXMOX:8006`

## Étapes post-déploiement

### 1. Installation de Debian
1. Connectez-vous à l'interface web Proxmox
2. Sélectionnez la VM "runner-vm" (200)
3. Cliquez sur "Console" pour ouvrir la console VNC
4. Suivez l'assistant d'installation Debian 12

### 2. Configuration réseau recommandée
- Configurez une IP statique ou utilisez DHCP selon votre infrastructure
- Installez les outils de base : `ssh`, `curl`, `wget`, `git`

### 3. Installation Docker (optionnel)
```bash
# Sur la VM Debian une fois installée
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
```

## Dépannage

### Erreurs communes

**Erreur : "ISO not found"**
- Vérifiez que l'ISO `debian-12.5.0-amd64-netinst.iso` est présente dans le stockage `local:iso/`
- Téléchargez l'ISO depuis le site officiel Debian si nécessaire

**Erreur : "Authentication failed"**
- Vérifiez les identifiants dans `secret_vars.yml`
- Assurez-vous que l'utilisateur `root` peut se connecter à l'API Proxmox

**Erreur : "Storage not available"**
- Vérifiez que le stockage `local-lvm` existe et a suffisamment d'espace
- Adaptez le paramètre `scsi0` si vous utilisez un autre stockage

**VM déjà existante**
- Le playbook mettra à jour la configuration existante
- Pour recréer complètement la VM, supprimez-la d'abord via l'interface Proxmox

### Logs utiles
```bash
# Logs Proxmox (sur le node Proxmox)
tail -f /var/log/pve/tasks/active

# Verbose Ansible
ansible-playbook playbooks/vm_runner.yml --extra-vars "@secret_vars.yml" -vvv
```

## Personnalisation

### Modifier les spécifications
Éditez le fichier `playbooks/vm_runner.yml` pour ajuster :
- `cores` : Nombre de CPU
- `memory` : RAM en Mo
- `scsi0` : Taille et type de stockage du disque
- `vmid` : ID de la VM (doit être unique)

### Utiliser une autre ISO
Modifiez le paramètre `cdrom` avec le chemin vers votre ISO :
```yaml
cdrom: "local:iso/votre-iso.iso"
```

## Intégration avec d'autres playbooks

Ce playbook peut être intégré dans une chaîne de déploiement plus large :

```yaml
# Exemple dans un playbook principal
- import_playbook: playbooks/vm_runner.yml
- import_playbook: playbooks/configure_docker.yml
- import_playbook: playbooks/deploy_applications.yml
```

---

**📝 Note :** Cette documentation couvre le déploiement de base. Pour des configurations avancées (réseau privé, stockage partagé, cluster multi-nœuds), consultez la documentation officielle de Proxmox VE. 