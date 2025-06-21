# 🌐 Architecture Réseau Proxmox - Guide Complet

## 📋 Vue d'ensemble

Ce document explique l'architecture réseau de votre installation Proxmox sur serveur dédié Hetzner, les différentes possibilités de connectivité et les bonnes pratiques.

## 🏗️ Architecture Réseau - Schémas

### 1. Architecture Physique Hetzner

```
┌─────────────────────────────────────────────────────────────────┐
│                        🌐 INTERNET                              │
└─────────────────────────┬───────────────────────────────────────┘
                          │
                          │ IP Publique: 167.235.118.227
                          │
┌─────────────────────────┴───────────────────────────────────────┐
│              🏢 DATACENTER HETZNER                              │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                🖥️  SERVEUR DÉDIÉ                        │   │
│  │                                                         │   │
│  │  ┌─────────────┐    ┌─────────────────────────────┐    │   │
│  │  │    eth0     │────│       PROXMOX VE           │    │   │
│  │  │ (interface  │    │                             │    │   │
│  │  │  physique)  │    │  ┌─────────┐ ┌─────────┐   │    │   │
│  │  └─────────────┘    │  │  vmbr0  │ │  vmbr1  │   │    │   │
│  │                     │  │(bridge  │ │(bridge  │   │    │   │
│  │                     │  │ public) │ │ privé)  │   │    │   │
│  │                     │  └─────────┘ └─────────┘   │    │   │
│  │                     └─────────────────────────────┘    │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

### 2. Configuration Réseau Détaillée

```
┌─────────────────────────────────────────────────────────────────┐
│                    PROXMOX VE - CONFIGURATION RÉSEAU            │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                     eth0                                │   │
│  │               (Interface physique)                      │   │
│  │                   Mode: manual                          │   │
│  │                  (Pas d'IP directe)                     │   │
│  └─────────────────────┬───────────────────────────────────┘   │
│                        │                                       │
│  ┌─────────────────────┴───────────────────────────────────┐   │
│  │                    vmbr0                                │   │
│  │               (Bridge principal)                        │   │
│  │                                                         │   │
│  │  🔹 IP: 167.235.118.227/32                            │   │
│  │  🔹 Gateway: 172.31.1.1                               │   │
│  │  🔹 Bridge-ports: eth0                                 │   │
│  │  🔹 Route spéciale: 172.31.1.1/32 dev vmbr0          │   │
│  │                                                         │   │
│  │  📡 Connecté à INTERNET                                │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                    vmbr1                                │   │
│  │                (Bridge privé)                           │   │
│  │                                                         │   │
│  │  🔹 IP: 192.168.100.1/24                              │   │
│  │  🔹 Bridge-ports: none                                 │   │
│  │  🔹 Réseau interne pour VMs                           │   │
│  │                                                         │   │
│  │  🏠 Réseau privé VMs                                   │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

### 3. Connectivité des VMs

```
┌─────────────────────────────────────────────────────────────────┐
│                      SCÉNARIOS DE CONNECTIVITÉ                  │
│                                                                 │
│  🌐 INTERNET                                                   │
│       │                                                         │
│       │                                                         │
│  ┌────┴─────────────────────────────────────────────────────┐   │
│  │                    PROXMOX HOST                          │   │
│  │                 IP: 167.235.118.227                     │   │
│  │                                                          │   │
│  │  ┌─────────────┐              ┌─────────────┐          │   │
│  │  │    vmbr0    │              │    vmbr1    │          │   │
│  │  │   PUBLIC    │              │   PRIVÉ     │          │   │
│  │  └─────┬───────┘              └─────┬───────┘          │   │
│  │        │                            │                  │   │
│  │        │                            │                  │   │
│  │  ┌─────┴───────┐              ┌─────┴───────┐          │   │
│  │  │    VM1      │              │    VM2      │          │   │
│  │  │ (Web Server)│              │ (Database)  │          │   │
│  │  │ Interface   │              │ Interface   │          │   │
│  │  │ sur vmbr0   │              │ sur vmbr1   │          │   │
│  │  │             │              │             │          │   │
│  │  │ 🌐 ACCÈS    │              │ 🏠 PRIVÉ    │          │   │
│  │  │ INTERNET    │              │ SEULEMENT   │          │   │
│  │  └─────────────┘              └─────────────┘          │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

## 🚨 Pourquoi `01_safe_network_config.yml` est CRITIQUE

### Configuration Hetzner Spécifique

```yaml
# AVANT (Installation Debian de base)
auto eth0
iface eth0 inet static
    address 167.235.118.227/24
    gateway 172.31.1.1

# APRÈS (Configuration Proxmox optimisée)
auto eth0
iface eth0 inet manual

auto vmbr0
iface vmbr0 inet static
    address 167.235.118.227/32  # ⚠️ /32 au lieu de /24
    gateway 172.31.1.1
    bridge-ports eth0
    up ip route add 172.31.1.1/32 dev vmbr0  # ⚠️ Route spéciale
```

### ⚠️ Risques si mal configuré

1. **Perte de connectivité SSH** - Plus d'accès au serveur
2. **Isolation réseau** - VMs sans internet
3. **Routing cassé** - Communication impossible
4. **Nécessité de console rescue** - Intervention manuelle requise

## 🔧 Solutions de Connectivité pour vos VMs

### 1. 🌐 Port Forwarding (Recommandé)

**Principe :** Rediriger des ports spécifiques vers vos VMs

```bash
# Exemple : Rediriger le port 8080 vers VM (192.168.100.10:80)
iptables -t nat -A PREROUTING -p tcp --dport 8080 -j DNAT --to-destination 192.168.100.10:80
iptables -A FORWARD -p tcp -d 192.168.100.10 --dport 80 -j ACCEPT
```

**Avantages :**
- ✅ Sécurisé (exposition limitée)
- ✅ Contrôle granulaire
- ✅ Pas besoin d'IPs supplémentaires

**Cas d'usage :**
- Serveur web : Port 80/443 → VM
- SSH vers VM : Port 2222 → VM:22
- Services spécifiques

### 2. 🔗 VPN (Option Avancée)

**Principe :** Créer un tunnel sécurisé vers le réseau privé

```
┌─────────────────┐    VPN Tunnel    ┌─────────────────┐
│   VOTRE PC      │◄────────────────►│   PROXMOX       │
│ 192.168.1.100   │                  │ 192.168.100.1   │
└─────────────────┘                  └─────────────────┘
                                             │
                                    ┌─────────────────┐
                                    │      VMs        │
                                    │ 192.168.100.x   │
                                    └─────────────────┘
```

**Solutions VPN recommandées :**
- **WireGuard** (moderne, performant)
- **OpenVPN** (mature, compatible)
- **Tailscale** (simple, cloud-based)

### 3. 🔍 Scanner vos VMs depuis votre PC local

#### Option A : Port Forwarding + Nmap
```bash
# Scanner la VM via port forwarding
nmap -p 22,80,443 167.235.118.227

# Scanner des ports spécifiques redirigés
nmap -p 2222,8080,8443 167.235.118.227
```

#### Option B : VPN + Scan direct
```bash
# Une fois connecté au VPN
nmap -sn 192.168.100.0/24  # Découverte réseau
nmap -p 1-65535 192.168.100.10  # Scan complet d'une VM
```

#### Option C : Proxy SSH (Simple et rapide)
```bash
# Tunnel SSH vers Proxmox
ssh -L 8080:192.168.100.10:80 root@167.235.118.227

# Puis accéder à http://localhost:8080
```

## 🛠️ Scripts d'Automatisation

### Script de Port Forwarding

```bash
#!/bin/bash
# port_forward_setup.sh

# Configuration des variables
PROXMOX_IP="167.235.118.227"
VM_NETWORK="192.168.100.0/24"

# Activation du forwarding IP
echo 1 > /proc/sys/net/ipv4/ip_forward

# Règles NAT pour les VMs
iptables -t nat -A POSTROUTING -s $VM_NETWORK -o vmbr0 -j MASQUERADE

# Exemples de redirections
# Web server VM (192.168.100.10)
iptables -t nat -A PREROUTING -p tcp --dport 8080 -j DNAT --to-destination 192.168.100.10:80
iptables -A FORWARD -p tcp -d 192.168.100.10 --dport 80 -j ACCEPT

# SSH vers VM
iptables -t nat -A PREROUTING -p tcp --dport 2222 -j DNAT --to-destination 192.168.100.10:22
iptables -A FORWARD -p tcp -d 192.168.100.10 --dport 22 -j ACCEPT

# Sauvegarder les règles
iptables-save > /etc/iptables/rules.v4
```

## 🔐 Considérations de Sécurité

### Bonnes Pratiques

1. **Firewall strict** sur l'hôte Proxmox
2. **Exposition minimale** - Seulement les ports nécessaires
3. **Monitoring** des connexions
4. **Fail2ban** pour protection SSH
5. **Certificats SSL** pour services web

### Exemple de configuration Firewall

```bash
# Bloquer tout par défaut
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# Autoriser loopback
iptables -A INPUT -i lo -j ACCEPT

# Autoriser connexions établies
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# SSH Proxmox
iptables -A INPUT -p tcp --dport 22 -j ACCEPT

# Interface web Proxmox
iptables -A INPUT -p tcp --dport 8006 -j ACCEPT

# Ports pour VMs (exemples)
iptables -A INPUT -p tcp --dport 8080 -j ACCEPT  # Web VM
iptables -A INPUT -p tcp --dport 2222 -j ACCEPT  # SSH VM
```

## 📊 Tableaux de Référence

### Comparaison des Solutions

| Solution | Complexité | Sécurité | Performance | Cas d'usage |
|----------|------------|----------|-------------|-------------|
| **Port Forwarding** | Faible | Bonne | Excellente | Services spécifiques |
| **VPN** | Moyenne | Excellente | Bonne | Accès complet réseau |
| **Proxy SSH** | Faible | Bonne | Moyenne | Tests/développement |

### Ports Standards

| Service | Port Standard | Port Forwarding Suggéré |
|---------|---------------|-------------------------|
| SSH | 22 | 2222 |
| HTTP | 80 | 8080 |
| HTTPS | 443 | 8443 |
| MySQL | 3306 | 3307 |
| PostgreSQL | 5432 | 5433 |

## 🚀 Ordre d'Exécution des Playbooks

### Séquence Recommandée

```
1. 00_install_proxmox.yml     → Installation base + hostname "pve"
   ⚠️  REDÉMARRAGE MANUEL OBLIGATOIRE

2. 01_safe_network_config.yml → Configuration bridges réseau
   ⚠️  CRITIQUE - Modifie /etc/network/interfaces

3. 02_add_private_bridge.yml  → Ajout bridge privé vmbr1

4. 99_post_install_check.yml  → Vérifications finales
```

### Commandes d'Exécution

```bash
# 1. Installation Proxmox
ansible-playbook -i inventory.yml playbooks/00_install_proxmox.yml

# 2. REDÉMARRAGE MANUEL via console/reboot

# 3. Configuration réseau (CRITIQUE)
ansible-playbook -i inventory.yml playbooks/01_safe_network_config.yml

# 4. Bridge privé
ansible-playbook -i inventory.yml playbooks/02_add_private_bridge.yml

# 5. Vérifications
ansible-playbook -i inventory.yml playbooks/99_post_install_check.yml
```

## 🚀 Prochaines Étapes Recommandées

1. **✅ FAIT** - Suppression de `configure_network.yml` (redondant)
2. **Tester** la configuration réseau actuelle
3. **Implémenter** le port forwarding pour vos services
4. **Considérer** un VPN si accès fréquent aux VMs
5. **Documenter** vos règles de forwarding

## ⚠️ Points d'Attention Critiques

- **TOUJOURS** sauvegarder `/etc/network/interfaces` avant modification
- **TESTER** la connectivité SSH après chaque changement réseau
- **AVOIR** un accès console de secours (KVM Hetzner)
- **VÉRIFIER** que les VMs peuvent accéder à internet après configuration

## 🔧 Diagnostic et Dépannage

### Commandes de Vérification

```bash
# Vérifier les bridges
ip link show

# Vérifier les routes
ip route show

# Vérifier les interfaces
cat /etc/network/interfaces

# Tester la connectivité
ping 8.8.8.8

# Vérifier les règles iptables
iptables -L -n
iptables -t nat -L -n
```

### Problèmes Courants

1. **Pas d'accès internet pour VMs** → Vérifier NAT/Masquerading
2. **Port forwarding ne fonctionne pas** → Vérifier règles iptables
3. **Perte de connexion SSH** → Console rescue nécessaire
4. **VMs isolées** → Vérifier configuration bridges

---

Cette architecture est optimisée pour Hetzner et suit les meilleures pratiques de sécurité réseau. N'hésitez pas à adapter selon vos besoins spécifiques ! 