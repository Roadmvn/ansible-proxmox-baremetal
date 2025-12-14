# Workflow Complet - Création Cluster Proxmox VE

Guide étape par étape pour créer un cluster Proxmox VE avec Ansible.

## Table des matières

1. [Prérequis](#prérequis)
2. [Configuration initiale](#configuration-initiale)
3. [Configuration Ansible Vault](#configuration-ansible-vault)
4. [Création du cluster](#création-du-cluster)
5. [Vérification](#vérification)
6. [Opérations courantes](#opérations-courantes)
7. [Troubleshooting](#troubleshooting)

## Prérequis

### Infrastructure

- 2+ serveurs avec Proxmox VE installé
- Connectivité réseau entre tous les serveurs (port 22, 8006, 5404-5405)
- Accès root aux serveurs
- Clé SSH publique locale (ex: `~/.ssh/id_ed25519.pub`)

### Logiciels locaux

```bash
# Vérifier les installations
ansible --version      # Version 2.10+
python3 --version      # Python 3.8+
make --version         # GNU Make
```

### État des serveurs

Les serveurs doivent être:
- En mode **standalone** (pas encore en cluster)
- Accessibles via SSH avec mot de passe root
- Avec Proxmox VE installé et fonctionnel

## Configuration initiale

### 1. Cloner le dépôt

```bash
git clone <repository-url>
cd ansible-proxmox-baremetal/ansible
```

### 2. Configurer l'inventaire

Éditer le fichier d'inventaire pour le cluster:

```bash
# Copier depuis l'exemple si nécessaire
cp inventory/proxmox-cluster.ini.example inventory/proxmox-cluster.ini

# Éditer avec vos informations
vi inventory/proxmox-cluster.ini
```

Structure du fichier:

```ini
# Nœud primaire (celui qui crée le cluster)
[proxmox_cluster_primary]
pve1 ansible_host=10.0.0.1 ansible_user=root hostname=pve1.localdomain

# Nœuds secondaires (ceux qui rejoignent)
[proxmox_cluster_nodes]
pve2 ansible_host=10.0.0.2 ansible_user=root hostname=pve2.localdomain

# Groupe parent
[proxmox_cluster:children]
proxmox_cluster_primary
proxmox_cluster_nodes

# Variables communes
[proxmox_cluster:vars]
ansible_ssh_private_key_file=~/.ssh/id_ed25519
ansible_python_interpreter=/usr/bin/python3
cluster_name=pve-cluster
```

### 3. Tester la connectivité

```bash
make test-cluster
```

Si les serveurs ne sont pas encore configurés pour SSH par clé, c'est normal. Le processus de création du cluster configurera automatiquement SSH.

## Configuration des credentials

Configuration simple et directe dans le fichier d'inventaire.

### Éditer l'inventaire avec vos credentials

```bash
cd ansible
vi inventory/proxmox-cluster.ini
```

Modifiez les lignes avec vos informations :

```ini
# Nœud primaire du cluster
[proxmox_cluster_primary]
pve1 ansible_host=10.0.0.1 ansible_user=root hostname=pve1.localdomain ansible_password=votre_mdp_root

# Nœuds secondaires
[proxmox_cluster_nodes]
pve2 ansible_host=10.0.0.2 ansible_user=root hostname=pve2.localdomain ansible_password=votre_mdp_root
```

**Note** :
- Chaque serveur peut avoir un mot de passe différent
- La clé SSH publique sera lue automatiquement depuis `~/.ssh/id_ed25519.pub`
- Le mot de passe est utilisé uniquement pour la configuration SSH initiale

## Création du cluster

### Workflow automatisé en 6 phases

Le playbook `create-proxmox-cluster.yml` exécute automatiquement 6 phases:

```
Phase 1: Préparation SSH
├─ Configure SSH avec authentification par clé
├─ Utilise le mot de passe root pour connexion initiale
└─ Détecte le mode (standalone/cluster)

Phase 2: Vérifications préalables
├─ Vérifie que Proxmox VE est installé
├─ Teste la connectivité réseau
├─ Vérifie qu'aucun cluster n'existe déjà
└─ Valide tous les prérequis

Phase 3: Création du cluster (nœud primaire)
├─ Exécute pvecm create sur le nœud primaire
├─ Attend la stabilisation du cluster filesystem
├─ Redémarre Corosync
└─ Vérifie la création du cluster

Phase 4: Jonction au cluster (nœuds secondaires)
├─ Joint chaque nœud un par un (serial: 1)
├─ Exécute pvecm add avec --use_ssh
├─ Attend la synchronisation de la configuration
└─ Vérifie la jonction réussie

Phase 5: Reconfiguration SSH post-cluster
├─ Détecte que /root/.ssh est maintenant un symlink
├─ Configure SSH pour accepter les clés de /etc/pve/priv/
├─ S'assure que la clé de contrôle Ansible est présente
└─ Configure sshd pour les deux emplacements

Phase 6: Vérifications finales
├─ Vérifie le statut du cluster (pvecm status)
├─ Liste les nœuds (pvecm nodes)
├─ Vérifie Corosync (corosync-cfgtool -s)
├─ Contrôle le quorum
└─ Affiche le résumé de succès
```

### Lancer la création

```bash
make create-cluster
```

Le processus vous demandera confirmation, puis:

1. Configurera SSH sur tous les nœuds (Phase 1)
2. Vérifiera les prérequis (Phase 2)
3. Créera le cluster sur le nœud primaire (Phase 3)
4. Joindra les nœuds secondaires un par un (Phase 4)
5. Reconfigurera SSH pour le mode cluster (Phase 5)
6. Vérifiera que tout fonctionne (Phase 6)

**Durée estimée**: 5-10 minutes selon le nombre de nœuds.

### Sortie attendue

```
============================================
PHASE 1: PREPARATION SSH
============================================
Configuration de l'authentification par clé SSH
...
✓ Phase 1 terminée avec succès

============================================
PHASE 2: VERIFICATIONS PREALABLES
============================================
...
✓ Phase 2 terminée - Tous les prérequis sont OK

============================================
PHASE 3: CREATION DU CLUSTER
============================================
Nœud primaire: pve1
Nom du cluster: pve-cluster
...
✓ Phase 3 terminée - Cluster créé sur pve1

============================================
PHASE 4: JONCTION AU CLUSTER
============================================
Nœud secondaire: pve2
...
✓ Phase 4 terminée - pve2 a rejoint le cluster

============================================
PHASE 5: RECONFIGURATION SSH POST-CLUSTER
============================================
...
✓ Phase 5 terminée - SSH reconfiguré pour le mode cluster

============================================
PHASE 6: VERIFICATIONS FINALES
============================================
...
✓ CLUSTER PROXMOX VE CREE AVEC SUCCES
============================================
```

## Vérification

### Vérifier le cluster depuis Ansible

```bash
# Statut du cluster sur tous les nœuds
make cluster-status

# Liste des nœuds
make cluster-nodes

# Vérification complète de santé
make cluster-health
```

### Vérifier depuis un nœud

Connectez-vous en SSH à n'importe quel nœud:

```bash
ssh root@10.0.0.1

# Statut du cluster
pvecm status

# Liste des nœuds
pvecm nodes

# Vérifier le quorum
pvecm status | grep Quorate

# Vérifier Corosync
corosync-cfgtool -s

# Vérifier le cluster filesystem
ls -la /etc/pve/nodes/
```

### Vérifier l'interface web

Accédez à l'interface web de n'importe quel nœud:

```
https://10.0.0.1:8006
https://10.0.0.2:8006
```

Dans le menu "Datacenter", vous devriez voir tous les nœuds du cluster.

## Opérations courantes

### Ajouter un nouveau nœud au cluster

1. Installer Proxmox VE sur le nouveau serveur
2. Ajouter le nœud dans `inventory/proxmox-cluster.ini`:

```ini
[proxmox_cluster_nodes]
pve2 ansible_host=10.0.0.2 ansible_user=root hostname=pve2.localdomain
pve3 ansible_host=10.0.0.3 ansible_user=root hostname=pve3.localdomain  # Nouveau
```

3. Relancer le playbook (il détectera le cluster existant et ajoutera seulement le nouveau nœud):

```bash
make create-cluster
```

### Vérifier la santé du cluster

```bash
# Vérification complète
make cluster-health

# Ou commandes individuelles
make cluster-status
make cluster-nodes
```

### Modifier les credentials

```bash
# Éditer l'inventaire
vi inventory/proxmox-cluster.ini

# Modifier les mots de passe selon vos besoins
# Chaque serveur peut avoir un mot de passe différent
```

### Détruire le cluster

**Attention**: Cette opération remet les nœuds en mode standalone.

```bash
make destroy-cluster
```

Confirmez en tapant `destroy` quand demandé.

## Troubleshooting

### Problème: "Permission denied (publickey,password)"

**Cause**: SSH ne peut pas se connecter

**Solution**:
```bash
# Vérifier les credentials dans l'inventaire
cat inventory/proxmox-cluster.ini

# Vérifier la connectivité réseau
ping 10.0.0.1

# Tester SSH manuellement avec le mot de passe
ssh root@10.0.0.1
```

### Problème: "Quorum not reached"

**Cause**: Pas assez de nœuds actifs pour le quorum

**Solution** (cluster 2 nœuds):
```bash
# Se connecter au nœud actif
ssh root@10.0.0.1

# Ajuster le quorum attendu (temporaire)
pvecm expected 1

# Vérifier
pvecm status
```

### Problème: "Corosync not running"

**Cause**: Service Corosync arrêté

**Solution**:
```bash
# Via Ansible
ansible -i inventory/proxmox-cluster.ini proxmox_cluster -m systemd -a "name=corosync state=started enabled=yes" -b

# Ou manuellement sur le nœud
systemctl start corosync
systemctl status corosync
journalctl -u corosync -n 50
```

### Problème: "Cluster already exists"

**Cause**: Un cluster existe déjà sur les nœuds

**Solutions**:

**Option 1**: Forcer la recréation (détruit et recrée)
```bash
make destroy-cluster
make create-cluster
```

**Option 2**: Passer la vérification (si vous savez ce que vous faites)
```bash
ansible-playbook -i inventory/proxmox-cluster.ini playbooks/create-proxmox-cluster.yml \
  -e force_cluster_recreation=true
```

### Problème: SSH se casse après création du cluster

**Cause**: Ancien problème, maintenant résolu par Phase 5

**Solution**: Le nouveau playbook gère automatiquement ce cas. Si vous utilisez l'ancien playbook:

```bash
# Mettre à jour vers le nouveau playbook
git pull origin main
make create-cluster
```

### Logs et debugging

```bash
# Exécuter en mode verbose
ansible-playbook -i inventory/proxmox-cluster.ini playbooks/create-proxmox-cluster.yml -v

# Très verbose (debug)
ansible-playbook -i inventory/proxmox-cluster.ini playbooks/create-proxmox-cluster.yml -vvv

# Vérifier les logs Corosync sur un nœud
ssh root@10.0.0.1
journalctl -u corosync -f

# Vérifier les logs pve-cluster
journalctl -u pve-cluster -f
```

## Architecture et fichiers

### Structure du projet

```
ansible/
├── playbooks/
│   ├── create-proxmox-cluster.yml      # Playbook principal (6 phases)
│   └── destroy-proxmox-cluster.yml     # Destruction du cluster
├── roles/
│   ├── proxmox-ssh-setup/              # Configuration SSH intelligente
│   │   ├── tasks/main.yml              # Détection mode + config SSH
│   │   ├── defaults/main.yml           # Variables par défaut
│   │   ├── handlers/main.yml           # Rechargement SSH
│   │   └── meta/main.yml               # Métadonnées
│   └── proxmox-cluster-create/         # (Ancien, conservé pour compatibilité)
├── inventory/
│   ├── proxmox-cluster.ini             # Inventaire cluster (votre config + credentials)
│   └── proxmox-cluster.ini.example     # Template d'exemple
├── group_vars/
│   └── proxmox_cluster/
│       └── vars.yml                    # Variables publiques
├── Makefile                             # Commandes make
└── ansible.cfg                          # Configuration Ansible
```

### Rôle proxmox-ssh-setup

Le nouveau rôle `proxmox-ssh-setup` est intelligent:

**Mode standalone** (avant cluster):
- `/root/.ssh` est un répertoire normal
- Crée `/root/.ssh/authorized_keys` avec la clé de contrôle

**Mode cluster** (après cluster):
- `/root/.ssh` est un symlink vers `/etc/pve/priv/`
- Ajoute la clé dans `/etc/pve/priv/authorized_keys`
- Configure sshd pour accepter les deux emplacements:
  ```
  AuthorizedKeysFile .ssh/authorized_keys /etc/pve/priv/authorized_keys
  ```

Cette approche respecte l'architecture de Proxmox au lieu de la combattre.

## Références

### Documentation Proxmox

- [Proxmox VE Cluster Manager](https://pve.proxmox.com/wiki/Cluster_Manager)
- [Proxmox VE Configuration](https://pve.proxmox.com/wiki/Proxmox_VE_Configuration)
- [Corosync Configuration](https://pve.proxmox.com/wiki/Corosync)

### Documentation Ansible

- [Ansible Best Practices](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html)
- [Ansible Inventory](https://docs.ansible.com/ansible/latest/user_guide/intro_inventory.html)

### Commandes utiles

```bash
# Proxmox
pvecm status          # Statut cluster
pvecm nodes           # Liste nœuds
pvecm expected 1      # Ajuster quorum
pvecm delnode <name>  # Supprimer nœud

# Corosync
corosync-cfgtool -s   # Statut Corosync
corosync-quorumtool   # Informations quorum

# Cluster Filesystem
df -h /etc/pve        # Espace pmxcfs
cat /etc/pve/.members # Membres actifs

# SSH
ssh-keygen -R <ip>    # Supprimer clé host
ssh-copy-id root@<ip> # Copier clé SSH
```

## Support et contribution

### Signaler un problème

Si vous rencontrez un problème:

1. Vérifier la section [Troubleshooting](#troubleshooting)
2. Consulter les logs avec `-vvv`
3. Créer une issue avec:
   - Description du problème
   - Sortie complète de la commande
   - Versions (Ansible, Proxmox, Python)

### Contribuer

Les contributions sont bienvenues ! Voir `CONTRIBUTING.md` pour les guidelines.
