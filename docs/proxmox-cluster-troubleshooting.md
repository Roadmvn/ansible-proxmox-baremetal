# Guide de Dépannage - Cluster Proxmox VE

Solutions aux problèmes courants lors de la création et gestion d'un cluster Proxmox VE.

## Problèmes de Création du Cluster

### Erreur : "cluster network not configured"

**Cause** : Le réseau cluster n'est pas accessible ou mal configuré.

**Diagnostic** :
```bash
# Vérifier la connectivité réseau
ping -c 3 <IP_AUTRE_NOEUD>

# Vérifier les interfaces réseau
ip addr show

# Tester les ports cluster
telnet <IP_AUTRE_NOEUD> 5405
```

**Solutions** :
1. Vérifier que les nœuds peuvent se joindre :
   ```bash
   ssh root@<IP_AUTRE_NOEUD>
   ```

2. Vérifier le firewall :
   ```bash
   # Proxmox devrait avoir configuré le firewall automatiquement
   # Mais vérifier quand même
   iptables -L -n | grep 540
   ```

3. Ouvrir les ports si nécessaire :
   ```bash
   # Sur tous les nœuds
   ufw allow 5404/udp
   ufw allow 5405/udp
   ufw allow 5403/tcp
   ```

### Erreur : "cluster already exists"

**Cause** : Le nœud fait déjà partie d'un cluster.

**Diagnostic** :
```bash
# Vérifier la configuration cluster existante
pvecm status

# Voir la configuration Corosync
cat /etc/pve/corosync.conf
```

**Solutions** :

Option 1 : Rejoindre le cluster existant au lieu d'en créer un nouveau

Option 2 : Détruire le cluster existant et en créer un nouveau
```bash
# ATTENTION : Détruit toute la configuration cluster !

# Sur le nœud à nettoyer
systemctl stop pve-cluster corosync

# Sauvegarder la configuration
cp -r /etc/pve /root/pve-backup-$(date +%Y%m%d)

# Nettoyer
rm -rf /etc/pve /etc/corosync/*
rm -f /var/lib/corosync/*

# Redémarrer
reboot
```

### Erreur : "hostname does not match"

**Cause** : Le hostname du système ne correspond pas à celui de Proxmox.

**Diagnostic** :
```bash
# Vérifier le hostname système
hostname

# Vérifier le hostname dans Proxmox
cat /etc/hostname

# Vérifier /etc/hosts
cat /etc/hosts
```

**Solutions** :
```bash
# Définir le hostname correct
hostnamectl set-hostname pve1.localdomain

# Mettre à jour /etc/hosts
nano /etc/hosts
# Ajouter :
# 127.0.1.1 pve1.localdomain pve1

# Redémarrer les services
systemctl restart pvedaemon pveproxy
```

## Problèmes de Jonction au Cluster

### Erreur : "unable to join cluster"

**Cause** : Problème de connectivité ou d'authentification.

**Diagnostic** :
```bash
# Tester SSH vers le nœud primaire
ssh root@<IP_NOEUD_PRIMAIRE>

# Vérifier que pvecm fonctionne sur le primaire
ssh root@<IP_NOEUD_PRIMAIRE> 'pvecm status'
```

**Solutions** :

1. Vérifier les clés SSH :
   ```bash
   # Sur le nœud qui tente de rejoindre
   ssh-keyscan <IP_NOEUD_PRIMAIRE> >> ~/.ssh/known_hosts
   ```

2. Utiliser le flag `--use_ssh` :
   ```bash
   pvecm add <IP_NOEUD_PRIMAIRE> --use_ssh
   ```

3. Vérifier le mot de passe root :
   ```bash
   # Le mot de passe root doit être identique ou SSH configuré
   passwd root
   ```

### Erreur : "corosync.conf already exists"

**Cause** : Un fichier de configuration Corosync existe déjà.

**Solutions** :
```bash
# Sauvegarder l'ancienne configuration
mv /etc/corosync/corosync.conf /etc/corosync/corosync.conf.old

# Réessayer de rejoindre
pvecm add <IP_NOEUD_PRIMAIRE> --use_ssh
```

### Le nœud joint mais n'apparaît pas dans le cluster

**Diagnostic** :
```bash
# Vérifier le statut
pvecm status

# Vérifier les logs
journalctl -u corosync -f
journalctl -u pve-cluster -f
```

**Solutions** :

1. Redémarrer les services cluster :
   ```bash
   systemctl restart corosync pve-cluster
   ```

2. Vérifier la synchronisation du filesystem :
   ```bash
   ls -la /etc/pve/nodes/
   # Doit afficher tous les nœuds
   ```

3. Forcer la synchronisation :
   ```bash
   systemctl restart pve-cluster
   ```

## Problèmes de Quorum

### Erreur : "cluster not quorate"

**Cause** : Pas assez de nœuds actifs pour atteindre le quorum.

**Diagnostic** :
```bash
pvecm status
# Regarder:
# Expected votes: 2
# Total votes: 1
# Quorate: No  ← PROBLEME
```

**Solutions** :

1. Avec 2 nœuds et 1 seul actif :
   ```bash
   # TEMPORAIRE : Ajuster le expected votes
   pvecm expected 1

   # Cela permet au cluster de fonctionner avec 1 nœud
   # ATTENTION : Remettre à 2 dès que possible !
   ```

2. Redémarrer le nœud inactif :
   ```bash
   ssh root@<IP_NOEUD_INACTIF>
   systemctl restart corosync pve-cluster
   ```

3. Si le nœud est définitivement perdu :
   ```bash
   # Sur un nœud actif
   pvecm delnode <nom_noeud_perdu>
   pvecm expected 1
   ```

### Split-brain (cerveau partagé)

**Cause** : Les nœuds ne peuvent pas communiquer entre eux mais sont tous actifs.

**Diagnostic** :
```bash
# Sur chaque nœud
pvecm status

# Si chaque nœud pense être seul dans le cluster → split-brain
```

**Solutions** :

1. Vérifier la connectivité réseau :
   ```bash
   ping <IP_AUTRE_NOEUD>
   traceroute <IP_AUTRE_NOEUD>
   ```

2. Arrêter tous les nœuds sauf le primaire :
   ```bash
   # Sur les nœuds secondaires
   systemctl stop corosync pve-cluster
   ```

3. Sur le primaire, ajuster le quorum :
   ```bash
   pvecm expected 1
   ```

4. Redémarrer les nœuds secondaires :
   ```bash
   systemctl start corosync pve-cluster
   ```

5. Rétablir le quorum normal :
   ```bash
   pvecm expected 2
   ```

## Problèmes de Synchronisation

### Les nœuds ne voient pas les mêmes VMs

**Cause** : Problème de synchronisation du Cluster Filesystem (CFS).

**Diagnostic** :
```bash
# Vérifier le statut CFS
pmxcfs -l

# Vérifier les fichiers
ls -la /etc/pve/nodes/
```

**Solutions** :

1. Redémarrer le service pve-cluster :
   ```bash
   systemctl restart pve-cluster
   ```

2. Vérifier les permissions :
   ```bash
   chown -R root:www-data /etc/pve
   chmod 755 /etc/pve
   ```

3. En dernier recours, forcer la re-synchronisation :
   ```bash
   systemctl stop pve-cluster
   rm -rf /var/lib/pve-cluster/config.db*
   systemctl start pve-cluster
   ```

### Configuration Corosync non synchronisée

**Diagnostic** :
```bash
# Comparer les fichiers sur chaque nœud
ssh pve1 'md5sum /etc/pve/corosync.conf'
ssh pve2 'md5sum /etc/pve/corosync.conf'
# Les sommes MD5 doivent être identiques
```

**Solutions** :
```bash
# Recharger la configuration Corosync
corosync-cfgtool -R

# Ou redémarrer Corosync
systemctl restart corosync
```

## Problèmes de Performance

### Haute latence dans le cluster

**Diagnostic** :
```bash
# Tester la latence réseau
ping -c 100 <IP_AUTRE_NOEUD> | tail -1

# Vérifier la charge système
top
htop

# Vérifier les I/O disque
iostat -x 1
```

**Solutions** :

1. Optimiser le réseau :
   ```bash
   # Augmenter les buffers réseau
   sysctl -w net.core.rmem_max=134217728
   sysctl -w net.core.wmem_max=134217728
   ```

2. Utiliser un réseau dédié pour le cluster :
   ```bash
   # Éditer /etc/pve/corosync.conf
   # Ajouter une interface de ring dédiée
   ```

3. Réduire la charge :
   ```bash
   # Migrer des VMs vers d'autres nœuds
   qm migrate <VMID> <TARGET_NODE>
   ```

### Services cluster redémarrent constamment

**Diagnostic** :
```bash
# Vérifier les logs
journalctl -u corosync | tail -50
journalctl -u pve-cluster | tail -50

# Vérifier l'état des services
systemctl status corosync pve-cluster
```

**Solutions** :

1. Vérifier les ressources système :
   ```bash
   free -h  # Mémoire
   df -h    # Disque
   ```

2. Augmenter les timeouts Corosync :
   ```bash
   # Éditer /etc/pve/corosync.conf
   # Dans la section totem, ajouter/modifier:
   # token: 10000
   # token_retransmits_before_loss_const: 10
   ```

3. Redémarrer les services proprement :
   ```bash
   systemctl stop pve-cluster corosync
   systemctl start corosync
   systemctl start pve-cluster
   ```

## Problèmes de Migration

### Migration échoue : "no such volume"

**Cause** : Le stockage n'est pas partagé ou accessible sur le nœud cible.

**Solutions** :

1. Vérifier que le stockage est configuré sur les deux nœuds :
   ```bash
   pvesm status
   ```

2. Pour un stockage local, utiliser la migration avec copie de disque :
   ```bash
   qm migrate <VMID> <TARGET> --online --with-local-disks
   ```

### Migration bloquée

**Diagnostic** :
```bash
# Vérifier les tâches en cours
qm status <VMID>

# Vérifier les logs
tail -f /var/log/syslog | grep qemu
```

**Solutions** :
```bash
# Annuler la migration bloquée
qm unlock <VMID>

# Réessayer
qm migrate <VMID> <TARGET>
```

## Commandes de Diagnostic

```bash
# Vérification complète du cluster
pvecm status              # Statut général
pvecm nodes               # Liste des nœuds
corosync-cfgtool -s       # Statut Corosync
corosync-quorumtool -l    # Informations quorum

# Logs
journalctl -u corosync -f           # Logs Corosync en temps réel
journalctl -u pve-cluster -f        # Logs cluster
tail -f /var/log/syslog | grep pve  # Logs Proxmox

# Réseau
ss -tulpn | grep -E '(5404|5405|5403)'  # Vérifier les ports
netstat -an | grep EST | grep 540       # Connexions établies

# Filesystem cluster
pmxcfs -l                  # Statut CFS
ls -la /etc/pve/nodes/     # Vérifier la sync
```

## Récupération d'Urgence

### Recréer un cluster après perte totale

Si tous les nœuds ont perdu la configuration cluster :

```bash
# Sur CHAQUE nœud, nettoyer
systemctl stop pve-cluster corosync
rm -rf /etc/pve /etc/corosync/*
rm -f /var/lib/corosync/*
reboot

# Après reboot, sur le nœud primaire
pvecm create nouveau-cluster

# Sur les autres nœuds
pvecm add <IP_PRIMAIRE> --use_ssh
```

### Restaurer depuis une sauvegarde

```bash
# Si vous avez sauvegardé /etc/pve
systemctl stop pve-cluster

# Restaurer la sauvegarde
cp -r /root/pve-backup-YYYYMMDD /etc/pve

# Redémarrer
systemctl start pve-cluster
```

## Obtenir de l'Aide

Si le problème persiste :

1. **Vérifier les logs** : `/var/log/syslog`, `journalctl -u corosync`, `journalctl -u pve-cluster`
2. **Forum Proxmox** : https://forum.proxmox.com/
3. **Documentation officielle** : https://pve.proxmox.com/wiki/
4. **Support** : your-email@example.com

Fournir :
- Sortie de `pvecm status`
- Sortie de `pvecm nodes`
- Logs pertinents
- Détails de la configuration réseau
- Version de Proxmox (`pveversion`)
