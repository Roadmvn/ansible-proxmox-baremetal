# Ansible - Déploiement Automatisé

Guide rapide pour déployer le système de backup Proxmox avec Ansible.

## 🚀 Quick Start

### Méthode 1 : Setup Automatique (Recommandé)

```bash
cd ansible
./scripts/setup.sh
```

Le script va :
1. Vous demander l'environnement (test ou production)
2. Configurer les IPs des nœuds
3. Demander les passwords (Kopia, SMTP)
4. Tester la connectivité
5. Vous donner les commandes pour déployer

### Méthode 2 : Configuration Manuelle

```bash
# 1. Choisir l'inventaire
cp inventory/test.ini.example inventory/test.ini
nano inventory/test.ini  # Remplir les IPs

# 2. Configurer les variables
nano group_vars/all.yml  # Remplir passwords

# 3. Tester
make test

# 4. Déployer
make deploy-test
```

## 📋 Commandes Disponibles (Makefile)

```bash
make help          # Afficher l'aide
make test          # Tester connectivité
make deploy-test   # Déployer sur nœud test
make deploy        # Déployer sur tous les nœuds
make deploy-one NODE=node1  # Déployer sur 1 nœud
make update        # Mettre à jour les scripts
make backup        # Lancer backup maintenant
make health        # Vérifier santé système
make check         # Vérifier config avant déploiement
make list          # Lister les backups
make logs NODE=node1  # Voir les logs
```

## 📂 Structure

```
ansible/
├── ansible.cfg              # Configuration Ansible locale
├── Makefile                 # Commandes simplifiées
├── README.md                # Ce fichier
│
├── inventory/               # Inventaires
│   ├── hosts.ini           # Par défaut (lien vers test ou prod)
│   ├── test.ini            # 1 nœud test
│   └── production.ini      # 3 nœuds production
│
├── group_vars/
│   └── all.yml             # Variables globales
│
├── playbooks/              # Playbooks spécialisés
│   ├── deploy.yml          # Déploiement complet
│   ├── update.yml          # Mise à jour
│   ├── backup-now.yml      # Backup immédiat
│   └── health-check.yml    # Vérification santé
│
├── roles/                  # Roles Ansible
│   ├── common/            # Dépendances
│   ├── kopia/             # Installation Kopia
│   └── proxmox-backup/    # Scripts backup
│
└── scripts/                # Scripts helper
    ├── setup.sh            # Setup interactif
    └── check.sh            # Vérification pré-déploiement
```

## 🎯 Scénarios d'Utilisation

### Scénario 1 : Premier Déploiement Test

```bash
# 1. Setup interactif
./scripts/setup.sh
# Choisir "Test (1 nœud)"

# 2. Vérifier la configuration
make check

# 3. Déployer
make deploy-test

# 4. Vérifier
make health
```

### Scénario 2 : Déploiement Production (3 nœuds)

```bash
# 1. Configurer pour production
./scripts/setup.sh
# Choisir "Production (3 nœuds)"

# 2. Vérifier
make check
make test

# 3. Déployer
make deploy

# 4. Vérifier tous les nœuds
make health
```

### Scénario 3 : Mise à Jour des Scripts

```bash
# Après modification du code
git pull

# Mettre à jour sur les nœuds
make update
```

### Scénario 4 : Lancer un Backup Manuel

```bash
# Sur tous les nœuds
make backup

# Sur un seul nœud
make backup-one NODE=node2
```

### Scénario 5 : Debugging

```bash
# Vérifier les logs d'un nœud
make logs NODE=node1

# Vérifier la santé
make health

# Lister les backups
make list
```

## 🔧 Configuration

### Inventaires

**Test** (`inventory/test.ini`) :
```ini
[proxmox_test]
node1 ansible_host=10.0.0.15 ansible_user=root node_name=node1
```

**Production** (`inventory/production.ini`) :
```ini
[proxmox_cluster]
node1 ansible_host=10.0.0.1 ansible_user=root node_name=node1 config_backup_offset=0
node2 ansible_host=10.0.0.2 ansible_user=root node_name=node2 config_backup_offset=20
node3 ansible_host=10.0.0.3 ansible_user=root node_name=node3 config_backup_offset=40
```

### Variables Importantes

Dans `group_vars/all.yml` :

```yaml
# Passwords (à remplir)
kopia_password: "PasswordFortKopia"
smtp_password: "PasswordEmail"

# SMTP (à configurer)
smtp_host: "smtp.your-provider.com"
smtp_port: "587"
smtp_user: "your-email@example.com"

# S3 (à configurer)
s3_bucket: "your-bucket-name"
s3_endpoint: "https://s3.your-provider.com"
```

## 🧪 Tests

### Test de Connectivité

```bash
# Tous les nœuds
make test

# Un nœud spécifique
make test-node NODE=node1
```

### Vérification Pré-Déploiement

```bash
./scripts/check.sh
```

Vérifie :
- ✓ Outils requis (ansible, terraform, git)
- ✓ Fichiers de configuration
- ✓ Clés SSH
- ✓ Connectivité
- ✓ Structure Ansible
- ✓ Syntaxe playbooks

### Dry-Run (Simulation)

```bash
# Voir ce qui serait fait sans vraiment déployer
make deploy-dry
```

## 🐛 Dépannage

### Erreur : "Host unreachable"

```bash
# Vérifier SSH manuellement
ssh root@10.0.0.15

# Copier la clé SSH
ssh-copy-id root@10.0.0.15

# Tester avec Ansible
ansible all -m ping -vvv
```

### Erreur : "Permission denied"

```bash
# Vérifier que vous utilisez root
# Dans inventory, vérifier : ansible_user=root

# Vérifier les clés SSH
ls -la ~/.ssh/id_rsa
```

### Passwords non configurés

```bash
# Vérifier les placeholders
grep CHANGEZ_MOI group_vars/all.yml

# Les remplacer
nano group_vars/all.yml
```

### Relancer le setup

```bash
# Si erreur pendant setup, simplement relancer
./scripts/setup.sh
```

## 📚 Documentation Complète

- [Installation générale](../docs/01-installation.md)
- [Configuration](../docs/02-configuration.md)
- [Utilisation](../docs/03-usage.md)
- [Dépannage](../docs/06-troubleshooting.md)

## 🆘 Support

En cas de problème :
1. Lancer `./scripts/check.sh` pour diagnostiquer
2. Vérifier les logs Ansible
3. Consulter [docs/06-troubleshooting.md](../docs/06-troubleshooting.md)
4. Contact : infrastructure@inter-gestion.com

---

**💡 Astuce** : Utilisez `make help` pour voir toutes les commandes disponibles !
