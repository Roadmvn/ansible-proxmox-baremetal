# 🏗️ Architecture de Déploiement

Ce document décrit l'architecture cible des machines virtuelles (VMs) déployées par ce projet d'automatisation.

## 🌐 Schéma de l'Infrastructure

```
┌─────────────────────────────────────────────────────────────────┐
│                           🌐 INTERNET                           │
└─────────────────────┬───────────────────────────────────────────┘
                      │
                      │ IP: 167.235.118.227
                      │
┌─────────────────────┴───────────────────────────────────────────┐
│                🏢 SERVEUR HETZNER DÉDIÉ                        │
│                                                                 │
│ ┌─────────────────────────────────────────────────────────────┐ │
│ │                   🖥️  PROXMOX VE                            │ │
│ │              Interface: :8006                               │ │
│ │                                                             │ │
│ │  ┌─────────────────────┐    ┌─────────────────────────────┐ │ │
│ │  │     🌉 vmbr0        │    │        🌉 vmbr1             │ │ │
│ │  │   (Réseau Public)   │    │     (Réseau Privé)          │ │ │
│ │  │ 167.235.118.224/26  │    │      10.0.1.0/24            │ │ │
│ │  └──────────┬──────────┘    └─────────┬───────────────────┘ │ │
│ │             │                         │                     │ │
│ │             │                         │                     │ │
│ │   ┌─────────┴─────────┐               │                     │ │
│ │   │   📍  proxy-vm    │               │                     │ │
│ │   │     (ID: 801)     │◄──────────────┤                     │ │
│ │   │ 167.235.118.228   │               │                     │ │
│ │   │   (Jump Host)     │               │                     │ │
│ │   └───────────────────┘               │                     │ │
│ │                                       │                     │ │
│ │                            ┌──────────┴──────────┐          │ │
│ │                            │    📍 frontend-vm   │          │ │
│ │                            │      (ID: 802)      │          │ │
│ │                            │     10.0.1.10       │          │ │
│ │                            └──────────┬──────────┘          │ │
│ │                                       │                     │ │
│ │                            ┌──────────┴──────────┐          │ │
│ │                            │    📍 backend-vm    │          │ │
│ │                            │      (ID: 803)      │          │ │
│ │                            │     10.0.1.20       │          │ │
│ │                            └──────────┬──────────┘          │ │
│ │                                       │                     │ │
│ │                            ┌──────────┴──────────┐          │ │
│ │                            │   📍 database-vm    │          │ │
│ │                            │      (ID: 804)      │          │ │
│ │                            │     10.0.1.30       │          │ │
│ │                            └─────────────────────┘          │ │
│ └─────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

## 🔗 Flux de Connexion SSH

```
🖥️  Ton PC (89.95.52.92)
    │
    │ ssh root@167.235.118.227
    ▼
🖥️  Proxmox (167.235.118.227)
    │
    │ ssh imane@167.235.118.228
    ▼
📍 proxy-vm (167.235.118.228) ◄─── Jump Host
    │
    ├─ ssh imane@10.0.1.10 ──► 📍 frontend-vm
    ├─ ssh imane@10.0.1.20 ──► 📍 backend-vm  
    └─ ssh imane@10.0.1.30 ──► 📍 database-vm
```

## 📋 Description des VMs

### 🌐 **Proxy VM** (`proxy-vm`)
- **VMID** : 801
- **IP Publique** : 167.235.118.228 (vmbr0)
- **IP Privée** : 10.0.1.1 (vmbr1) 
- **Rôle** : Jump Host + Reverse Proxy
- **Accès** : Directement depuis Internet

### 🎨 **Frontend VM** (`frontend-vm`)
- **VMID** : 802
- **IP** : 10.0.1.10 (vmbr1 uniquement)
- **Rôle** : Interface utilisateur (React, Vue, etc.)
- **Accès** : Via proxy-vm uniquement

### ⚙️ **Backend VM** (`backend-vm`)
- **VMID** : 803
- **IP** : 10.0.1.20 (vmbr1 uniquement)
- **Rôle** : API et logique métier
- **Accès** : Via proxy-vm uniquement

### 🗄️ **Database VM** (`database-vm`)
- **VMID** : 804
- **IP** : 10.0.1.30 (vmbr1 uniquement)
- **Rôle** : Base de données (MySQL, PostgreSQL, etc.)
- **Accès** : Via proxy-vm uniquement (le plus isolé)

## 🛡️ Sécurité par Couches

```
Niveau 1: 🌐 Pare-feu Hetzner Cloud
    ↓
Niveau 2: 🖥️ Proxmox (PVE Firewall)
    ↓  
Niveau 3: 📍 proxy-vm (UFW + SSH)
    ↓
Niveau 4: 🔒 Réseau Privé vmbr1
    ↓
Niveau 5: 📍 VMs Internes (UFW individuel)
```

## 🚀 Flux Applicatif (Exemple Web)

```
👤 Utilisateur
    │ HTTPS
    ▼
🌐 proxy-vm (Traefik/Nginx)
    │ HTTP interne
    ▼  
🎨 frontend-vm (Port 3000)
    │ API REST
    ▼
⚙️ backend-vm (Port 8000)  
    │ SQL
    ▼
🗄️ database-vm (Port 3306/5432)
```

Cette architecture garantit **l'isolation**, **la sécurité** et **la scalabilité** de ton infrastructure. 