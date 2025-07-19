# 🔐 Guide de Connexion SSH aux VMs Internes

## 📋 Table des Matières
- [Architecture Réseau](#architecture-réseau)
- [Méthodes de Connexion](#méthodes-de-connexion)
- [Configuration Avancée](#configuration-avancée)
- [Dépannage](#dépannage)
- [Bonnes Pratiques](#bonnes-pratiques)

---

## 🌐 Architecture Réseau

### Vue d'Ensemble de l'Infrastructure

```
Internet (ton PC)
    ↓ SSH port 22
🏢 SERVEUR HETZNER DÉDIÉ
    IP Publique: 167.235.118.227 (SEULE IP vraiment publique)
    ↓
🖥️ PROXMOX (PVE) installé directement sur le serveur
    Interface Web: https://167.235.118.227:8006
    SSH: root@167.235.118.227
    ↓
🌉 Pont vmbr0 (réseau INTERNE au serveur)
    Sous-réseau: 167.235.118.224/26
    ↓
🐧 VMs sur des IPs PRIVÉES
    ├─ proxy-vm: 167.235.118.228 (Jump Host)
    └─ Pont vmbr1 (réseau PRIVÉ 10.0.1.0/24)
        ├─ frontend-vm: 10.0.1.10
        ├─ backend-vm: 10.0.1.20
        └─ database-vm: 10.0.1.30
```

### Points Clés à Retenir

- **167.235.118.227** = SEULE vraie IP publique (Proxmox)
- **167.235.118.228** = IP privée du sous-réseau Hetzner (proxy-vm)
- **10.0.1.x** = IPs complètement privées (VMs internes)

---

## 🔑 Méthodes de Connexion

### Méthode 1 : Jump Host Manuel (2 étapes)

Cette méthode utilise deux connexions SSH successives.

**Étape 1 : Connexion à Proxmox**
```bash
ssh root@167.235.118.227
```

**Étape 2 : Depuis Proxmox, connexion à la VM**
```bash
# Vers la proxy-vm
ssh imane@167.235.118.228

# Vers les VMs privées (depuis proxy-vm)
ssh imane@10.0.1.10  # frontend-vm
ssh imane@10.0.1.20  # backend-vm
ssh imane@10.0.1.30  # database-vm
```

### Méthode 2 : Jump Host Direct (1 seule commande)

Cette méthode utilise l'option `-J` de SSH pour automatiser le saut.

**Connexion directe à la proxy-vm :**
```bash
ssh -J root@167.235.118.227 imane@167.235.118.228
```

**Connexion directe aux VMs privées :**
```bash
# Frontend (via Proxmox puis proxy-vm)
ssh -J root@167.235.118.227,imane@167.235.118.228 imane@10.0.1.10

# Backend (via Proxmox puis proxy-vm)
ssh -J root@167.235.118.227,imane@167.235.118.228 imane@10.0.1.20

# Database (via Proxmox puis proxy-vm)
ssh -J root@167.235.118.227,imane@167.235.118.228 imane@10.0.1.30
```

### Méthode 3 : Configuration SSH Simplifiée

Créer un fichier `~/.ssh/config` pour simplifier les connexions.

**Configuration recommandée :**
```bash
# Proxmox (serveur principal)
Host proxmox
    HostName 167.235.118.227
    User root
    IdentityFile ~/.ssh/id_rsa

# Proxy VM (accessible via Proxmox)
Host proxy-vm
    HostName 167.235.118.228
    User imane
    ProxyJump proxmox
    IdentityFile ~/.ssh/id_rsa

# VMs privées (accessibles via proxy-vm)
Host frontend-vm
    HostName 10.0.1.10
    User imane
    ProxyJump proxy-vm
    IdentityFile ~/.ssh/id_rsa

Host backend-vm
    HostName 10.0.1.20
    User imane
    ProxyJump proxy-vm
    IdentityFile ~/.ssh/id_rsa

Host database-vm
    HostName 10.0.1.30
    User imane
    ProxyJump proxy-vm
    IdentityFile ~/.ssh/id_rsa
```

**Avec cette configuration, les connexions deviennent :**
```bash
ssh proxmox        # Connexion directe à Proxmox
ssh proxy-vm       # Connexion directe à la proxy-vm
ssh frontend-vm    # Connexion directe à la frontend-vm
ssh backend-vm     # Connexion directe à la backend-vm
ssh database-vm    # Connexion directe à la database-vm
```

---

## ⚙️ Configuration Avancée

### Port Forwarding (optionnel)

Pour exposer directement certains services, tu peux configurer le port forwarding sur Proxmox.

**Exemple : Exposer le SSH de proxy-vm sur le port 2222 :**
```bash
# Sur Proxmox, ajouter une règle iptables
iptables -t nat -A PREROUTING -p tcp --dport 2222 -j DNAT --to-destination 167.235.118.228:22
iptables -A FORWARD -p tcp -d 167.235.118.228 --dport 22 -j ACCEPT

# Sauvegarder les règles
iptables-save > /etc/iptables/rules.v4
```

**Connexion directe avec port forwarding :**
```bash
ssh -p 2222 imane@167.235.118.227
```

### Transfert de Fichiers

**Via SCP avec Jump Host :**
```bash
# Copier un fichier vers la proxy-vm
scp -J root@167.235.118.227 fichier.txt imane@167.235.118.228:/home/imane/

# Copier un fichier vers une VM privée
scp -J root@167.235.118.227,imane@167.235.118.228 fichier.txt imane@10.0.1.10:/home/imane/
```

**Via Rsync avec Jump Host :**
```bash
# Synchroniser un dossier
rsync -avz -e "ssh -J root@167.235.118.227,imane@167.235.118.228" \
    /local/path/ imane@10.0.1.10:/remote/path/
```

---

## 🔧 Dépannage

### Problèmes Courants

**1. "Connection timed out" lors de la connexion à Proxmox**
- Vérifier le pare-feu Hetzner Cloud
- Confirmer que l'IP publique est correcte : `167.235.118.227`

**2. "Connection refused" depuis Proxmox vers les VMs**
- Vérifier que les VMs sont démarrées : `qm list`
- Tester la connectivité réseau : `ping 167.235.118.228`

**3. "Permission denied" lors de l'authentification**
- Vérifier les identifiants : `imane` / `imane`
- S'assurer que le service SSH est actif dans la VM

### Commandes de Diagnostic

**Sur Proxmox :**
```bash
# Voir les VMs en cours d'exécution
qm list

# Tester la connectivité vers une VM
ping 167.235.118.228

# Voir la configuration réseau
brctl show
ip addr show vmbr0
```

**Dans une VM :**
```bash
# Vérifier le service SSH
sudo systemctl status ssh

# Voir les connexions réseau
sudo ss -tlpn | grep :22

# Tester la connectivité externe
ping 8.8.8.8
```

---

## 🛡️ Bonnes Pratiques

### Sécurité

1. **Utiliser des clés SSH plutôt que des mots de passe**
   ```bash
   # Générer une clé SSH
   ssh-keygen -t rsa -b 4096 -C "ton@email.com"
   
   # Copier la clé sur les serveurs
   ssh-copy-id root@167.235.118.227
   ssh-copy-id -J root@167.235.118.227 imane@167.235.118.228
   ```

2. **Désactiver l'authentification par mot de passe**
   ```bash
   # Dans /etc/ssh/sshd_config
   PasswordAuthentication no
   PubkeyAuthentication yes
   ```

3. **Changer le port SSH par défaut** (optionnel)
   ```bash
   # Dans /etc/ssh/sshd_config
   Port 2222
   ```

### Performance

1. **Utiliser la compression SSH pour les transferts de fichiers**
   ```bash
   ssh -C -J root@167.235.118.227 imane@167.235.118.228
   ```

2. **Réutiliser les connexions SSH**
   ```bash
   # Dans ~/.ssh/config
   Host *
       ControlMaster auto
       ControlPath ~/.ssh/control-%r@%h:%p
       ControlPersist 10m
   ```

### Monitoring

1. **Surveiller les connexions SSH actives**
   ```bash
   # Voir qui est connecté
   who
   w
   
   # Voir les logs SSH
   sudo journalctl -u ssh -f
   ```

---

## 📚 Exemples Pratiques

### Déploiement d'Application

**Déployer sur la frontend-vm :**
```bash
# Connexion directe
ssh -J root@167.235.118.227,imane@167.235.118.228 imane@10.0.1.10

# Ou avec la config SSH
ssh frontend-vm

# Une fois connecté
git clone https://github.com/ton-repo/frontend.git
cd frontend
docker-compose up -d
```

### Monitoring des Services

**Vérifier tous les services en une fois :**
```bash
#!/bin/bash
# Script de monitoring

echo "=== Status Proxmox ==="
ssh root@167.235.118.227 "qm list"

echo "=== Status Proxy VM ==="
ssh -J root@167.235.118.227 imane@167.235.118.228 "docker ps"

echo "=== Status Frontend VM ==="
ssh -J root@167.235.118.227,imane@167.235.118.228 imane@10.0.1.10 "docker ps"

echo "=== Status Backend VM ==="
ssh -J root@167.235.118.227,imane@167.235.118.228 imane@10.0.1.20 "docker ps"
```

---

## 🎯 Résumé

**Pour les connexions quotidiennes, utilise la Méthode 3 (configuration SSH) qui est la plus pratique :**

1. Configure le fichier `~/.ssh/config` une seule fois
2. Utilise des commandes simples comme `ssh frontend-vm`
3. Tout le routage complexe est géré automatiquement

**Architecture à retenir :**
- **1 seule IP publique** : 167.235.118.227 (Proxmox)
- **Jump hosts obligatoires** : Proxmox → proxy-vm → VMs privées
- **Sécurité par couches** : Pare-feu + SSH + Réseau privé 