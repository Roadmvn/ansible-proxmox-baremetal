# Guide de Création d'un Cluster Proxmox VE

Guide complet pour créer un cluster Proxmox VE avec Ansible.

## Vue d'ensemble

Un cluster Proxmox VE permet de :
- Gérer plusieurs serveurs depuis une seule interface web
- Migrer des VMs/conteneurs entre nœuds (live migration)
- Partager la configuration entre tous les nœuds
- Haute disponibilité (HA) des VMs

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                   CLUSTER PROXMOX VE 8.x                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  pve1 (Primaire)              pve2 (Secondaire)                 │
│  ├─ Proxmox VE 8.x            ├─ Proxmox VE 8.x                │
│  ├─ Cluster Manager           ├─ Cluster Node                  │
│  ├─ Quorum                    ├─ Synchronisation               │
│  ├─ Corosync (5404-5405)      ├─ Corosync                      │
│  └─ /etc/pve (CFS)            └─ /etc/pve (sync)               │
│                                                                   │
│               Cluster File System (CFS)                         │
│              Configuration Synchronisée                         │
└─────────────────────────────────────────────────────────────────┘
```

## Prérequis

### Infrastructure

- **Au moins 2 serveurs** avec Proxmox VE 8.x installé
- **Réseau stable** entre les serveurs
- **Connectivité réseau** sur les ports suivants :
  - `5404/udp` - Corosync multicast
  - `5405/udp` - Corosync
  - `5403/tcp` - PMG Cluster
  - `8006/tcp` - Interface Web Proxmox
  - `3128/tcp` - SPICE proxy
  - `22/tcp` - SSH

### Configuration réseau

- **IP fixes** pour tous les nœuds
- **Hostname configuré** sur chaque nœud
- **Résolution DNS** ou `/etc/hosts` configuré
- **Pas de NAT** entre les nœuds du cluster

### Vérifications préalables

```bash
# Sur chaque nœud

# 1. Vérifier que Proxmox est installé
pveversion

# 2. Vérifier le hostname
hostname
# Doit retourner: pve1, pve2, etc.

# 3. Vérifier qu'aucun cluster n'existe
cat /etc/pve/corosync.conf
# Doit retourner: No such file or directory

# 4. Tester la connectivité réseau entre nœuds
ping -c 3 <IP_AUTRE_NOEUD>

# 5. Vérifier les ports
ss -tulpn | grep -E '(5404|5405|5403|8006)'
```

## Méthode 1 : Création Automatique avec Ansible (Recommandé)

### Étape 1 : Configuration de l'inventaire

```bash
cd ansible

# Copier l'exemple
cp inventory/proxmox-cluster.ini.example inventory/proxmox-cluster.ini

# Éditer avec vos IPs
nano inventory/proxmox-cluster.ini
```

Exemple de configuration :

```ini
[proxmox_cluster_primary]
pve1 ansible_host=10.0.0.1 ansible_user=root hostname=pve1.localdomain

[proxmox_cluster_nodes]
pve2 ansible_host=10.0.0.2 ansible_user=root hostname=pve2.localdomain

[proxmox_cluster:children]
proxmox_cluster_primary
proxmox_cluster_nodes

[proxmox_cluster:vars]
cluster_name=pve-cluster
```

### Étape 2 : Tester la connectivité

```bash
make test-cluster
```

Sortie attendue :
```
pve1 | SUCCESS => {
    "ping": "pong"
}
pve2 | SUCCESS => {
    "ping": "pong"
}
```

### Étape 3 : Créer le cluster

```bash
# Création interactive (avec confirmation)
make create-cluster

# Ou directement
ansible-playbook -i inventory/proxmox-cluster.ini playbooks/create-proxmox-cluster.yml
```

Le playbook va :
1. Vérifier que Proxmox est installé sur tous les nœuds
2. Créer le cluster sur le nœud primaire (pve1)
3. Joindre les nœuds secondaires (pve2, etc.)
4. Vérifier le quorum et la synchronisation

### Étape 4 : Vérifier le cluster

```bash
# Afficher le statut
make cluster-status

# Vérifier la santé complète
make cluster-health

# Lister les nœuds
make cluster-nodes
```

## Méthode 2 : Création Manuelle

Si vous préférez créer le cluster manuellement :

### Sur le nœud primaire (pve1)

```bash
ssh root@10.0.0.1

# Créer le cluster
pvecm create pve-cluster

# Vérifier la création
pvecm status
```

Sortie attendue :
```
Cluster information
==================
Name:              pve-cluster
Config Version:    1
Transport:         knet
Secure auth:       on
Quorum information
------------------
Date:              Thu Nov  7 12:00:00 2025
Quorum provider:   corosync_votequorum
Nodes:             1
Node ID:           0x00000001
Ring ID:           1.1
Quorate:           Yes

Votequorum information
----------------------
Expected votes:    1
Highest expected:  1
Total votes:       1
Quorum:            1
Flags:             Quorate

Membership information
----------------------
    Nodeid      Votes Name
0x00000001          1 pve1 (local)
```

### Sur chaque nœud secondaire (pve2)

```bash
ssh root@10.0.0.2

# Joindre le cluster
pvecm add 10.0.0.1 --use_ssh

# Entrer le mot de passe root de pve1 si demandé

# Vérifier la jonction
pvecm status
```

Sortie attendue :
```
Cluster information
==================
Name:              pve-cluster
Config Version:    2
...
Nodes:             2
...
Quorate:           Yes
...
Membership information
----------------------
    Nodeid      Votes Name
0x00000001          1 pve1
0x00000002          1 pve2 (local)
```

## Vérifications Post-Création

### 1. Vérifier le statut du cluster

```bash
# Sur n'importe quel nœud
pvecm status
```

Vérifier que :
- `Nodes: 2` (ou le nombre total de nœuds)
- `Quorate: Yes`
- Tous les nœuds sont listés

### 2. Vérifier les nœuds

```bash
pvecm nodes
```

Doit afficher tous les nœuds avec leur ID et statut.

### 3. Vérifier Corosync

```bash
corosync-cfgtool -s
```

Doit afficher les services Corosync actifs.

### 4. Vérifier la synchronisation

```bash
# Vérifier que tous les nœuds sont synchronisés
ls -la /etc/pve/nodes/

# Doit afficher tous les nœuds du cluster
# drwxr-xr-x 2 root www-data ... pve1
# drwxr-xr-x 2 root www-data ... pve2
```

### 5. Tester l'interface web

Accéder à l'interface web de n'importe quel nœud :
- `https://10.0.0.1:8006`
- `https://10.0.0.2:8006`

Les deux interfaces doivent afficher **tous les nœuds** du cluster.

## Tests de Fonctionnement

### Test 1 : Créer une VM sur pve1

```bash
# Via l'interface web ou en CLI
qm create 100 --name test-vm --memory 2048 --cores 2
```

Vérifier sur pve2 que la VM est visible.

### Test 2 : Migration à chaud

Si vous avez un stockage partagé (NFS, Ceph, etc.) :

```bash
# Migrer la VM 100 de pve1 vers pve2
qm migrate 100 pve2
```

### Test 3 : Arrêt d'un nœud

```bash
# Sur pve2
systemctl stop pve-cluster

# Attendre 10 secondes

# Sur pve1, vérifier le statut
pvecm status
# Le cluster doit toujours être quorate avec 1 seul nœud

# Redémarrer pve2
ssh root@10.0.0.2
systemctl start pve-cluster
```

## Configuration Avancée

### Ajuster le quorum pour 2 nœuds

Avec seulement 2 nœuds, si un nœud tombe, le cluster perd le quorum. Pour éviter cela :

```bash
# Sur le nœud actif
pvecm expected 1

# Ceci permet au cluster de fonctionner avec 1 seul nœud
# ATTENTION : À utiliser uniquement temporairement !
# Remettre à 2 quand les 2 nœuds sont de nouveau actifs
pvecm expected 2
```

### Ajouter un nœud supplémentaire

```bash
# Sur le nouveau nœud (pve3)
pvecm add <IP_NOEUD_EXISTANT> --use_ssh
```

### Supprimer un nœud du cluster

```bash
# Sur un nœud actif (pas celui à supprimer)
pvecm delnode pve2

# Sur le nœud supprimé, nettoyer la configuration
systemctl stop pve-cluster corosync
rm -rf /etc/pve /etc/corosync/*
rm /var/lib/corosync/*
```

## Commandes Utiles

```bash
# Statut du cluster
pvecm status

# Liste des nœuds
pvecm nodes

# Version de Corosync
corosync -v

# Statut des services Corosync
corosync-cfgtool -s

# Logs Corosync
journalctl -u corosync

# Logs du cluster
journalctl -u pve-cluster

# Fichier de configuration Corosync
cat /etc/pve/corosync.conf

# Vérifier la synchronisation CFS
pmxcfs -l
```

## Bonnes Pratiques

1. **Nombre de nœuds impair** : Préférer 3, 5, 7 nœuds pour éviter les problèmes de quorum
2. **Réseau dédié** : Utiliser un réseau séparé pour le trafic cluster si possible
3. **Temps synchronisé** : Utiliser NTP sur tous les nœuds
4. **Sauvegardes régulières** : Sauvegarder `/etc/pve/` régulièrement
5. **Surveillance** : Monitorer le statut du cluster et les logs

## Prochaines Étapes

- [Résolution de problèmes](proxmox-cluster-troubleshooting.md)
- [Configuration Haute Disponibilité](proxmox-ha-configuration.md)
- [Stockage partagé pour le cluster](proxmox-shared-storage.md)

## Ressources

- [Documentation officielle Proxmox Cluster](https://pve.proxmox.com/wiki/Cluster_Manager)
- [Corosync Documentation](https://corosync.github.io/corosync/)
- [Guide Proxmox HA](https://pve.proxmox.com/wiki/High_Availability)
