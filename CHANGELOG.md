# Changelog

Tous les changements notables de ce projet seront documentés dans ce fichier.

Le format est basé sur [Keep a Changelog](https://keepachangelog.com/fr/1.0.0/),
et ce projet adhère à [Semantic Versioning](https://semver.org/lang/fr/).

## [2.0.0] - 2025-11-07

### Refactorisation majeure - Cluster Proxmox VE

Refonte complète de la création de cluster Proxmox VE avec architecture robuste, gestion sécurisée des credentials et workflow automatisé.

### 🔒 Sécurité

- **Gestion simplifiée des credentials**
  - Mot de passe root défini dans l'inventaire par serveur
  - Ou passé via ligne de commande avec `-e "ansible_password=..."`
  - Clé SSH publique lue automatiquement depuis `~/.ssh/id_ed25519.pub`
  - Pas de complexité inutile, approche directe et pragmatique

### ✨ Nouvelles fonctionnalités

- **Rôle `proxmox-ssh-setup`** : Configuration SSH intelligente
  - Détection automatique du mode (standalone vs cluster)
  - Gère le symlink `/root/.ssh → /etc/pve/priv/` en mode cluster
  - Configure sshd pour accepter les clés des deux emplacements
  - Garantit la persistance de l'accès SSH après création du cluster
  - Totalement idempotent et réutilisable

- **Workflow automatisé en 6 phases**
  1. **Préparation SSH** : Configure l'authentification par clé (utilise mot de passe initial)
  2. **Vérifications préalables** : Vérifie Proxmox VE, connectivité, absence de cluster existant
  3. **Création cluster** : Crée le cluster sur le nœud primaire
  4. **Jonction nœuds** : Joint les nœuds secondaires un par un (serial: 1)
  5. **Reconfiguration SSH** : Adapte SSH pour le mode cluster
  6. **Vérifications finales** : Vérifie quorum, Corosync, synchronisation CFS

- **Commandes Makefile cluster**
  - `make test-cluster` - Tester connectivité des nœuds
  - `make create-cluster` - Créer le cluster Proxmox
  - `make destroy-cluster` - Détruire un cluster existant
  - `make cluster-status` - Afficher statut du cluster
  - `make cluster-health` - Vérifier santé complète du cluster

### 🔧 Corrections majeures

- **Fix Corosync startup failure**
  - `destroy-proxmox-cluster.yml` préserve maintenant `/var/lib/corosync`
  - Ne supprime que le contenu, pas le répertoire
  - Recrée le répertoire avec les bonnes permissions si nécessaire

- **Fix SSH persistence**
  - Nouvelle architecture respecte le symlink Proxmox
  - Configuration sshd pour les deux emplacements de clés
  - Plus de perte d'accès SSH après création du cluster

- **Fix quorum check**
  - Utilise regex `Quorate:\s+Yes` au lieu de string exacte
  - Gère les variations d'espacement dans la sortie pvecm
  - Plus d'échecs faux-positifs

### 📚 Documentation

- **Nouveau guide complet** : `docs/proxmox-cluster-workflow.md`
  - Workflow détaillé de A à Z
  - Configuration simplifiée des credentials
  - Opérations courantes (ajout nœud, vérification santé, etc.)
  - Section troubleshooting complète
  - Références et commandes utiles

### ⚡ Améliorations

- **Idempotence totale** : Le playbook peut être relancé sans problème
- **Gestion d'erreurs robuste** : Détection et gestion des cas d'erreur
- **Architecture propre** : Séparation des responsabilités (rôles, group_vars, inventory)
- **Messages informatifs** : Affichage clair des phases et de la progression
- **Support mode cluster existant** : Détecte si un cluster existe déjà
- **SSH inter-serveurs** : Configuration automatique SSH entre nœuds pour pvecm

### 🗑️ Suppression

- **Fichier temporaire** `setup-ssh-key.yml` supprimé (remplacé par le rôle `proxmox-ssh-setup`)
- **Code legacy** dans `create-proxmox-cluster.yml` (remplacement complet)

### 📁 Structure projet

```
ansible/
├── roles/
│   └── proxmox-ssh-setup/          # Nouveau rôle SSH intelligent
├── group_vars/
│   └── proxmox_cluster/
│       └── vars.yml                # Variables publiques
├── inventory/
│   └── proxmox-cluster.ini         # Configuration serveurs + credentials
├── playbooks/
│   ├── create-proxmox-cluster.yml  # Refactorisé complet (6 phases)
│   └── destroy-proxmox-cluster.yml # Corrigé (préserve /var/lib/corosync)
└── Makefile                         # Commandes cluster ajoutées
```

### 🎯 Migration depuis v1.1.0

Si vous utilisez déjà la v1.1.0 :

```bash
# 1. Mettre à jour le dépôt
git pull

# 2. Configurer l'inventaire avec les mots de passe
cd ansible
vi inventory/proxmox-cluster.ini
# Ajouter ansible_password=... pour chaque serveur

# 3. Si un cluster existe déjà, le détruire d'abord
make destroy-cluster

# 4. Recréer avec le nouveau workflow
make create-cluster
```

### 🐛 Problèmes résolus

- ❌ **SSH se cassait après création du cluster** → ✅ Résolu par rôle `proxmox-ssh-setup`
- ❌ **Corosync ne démarrait pas après destruction** → ✅ Résolu en préservant `/var/lib/corosync`
- ❌ **Mot de passe hardcodé dans les playbooks** → ✅ Résolu par credentials dans inventory
- ❌ **Quorum check échouait avec faux-positifs** → ✅ Résolu par regex flexible
- ❌ **SSH inter-serveurs manquant pour pvecm** → ✅ Résolu par génération clés SSH automatique
- ❌ **Interventions manuelles requises** → ✅ Processus 100% automatisé

### 🚀 Performances

- Durée création cluster : 5-10 minutes (selon nombre de nœuds)
- Zéro intervention manuelle requise
- Idempotent : peut être relancé sans danger

### Notes de version

**v2.0.0 - Version majeure**

**Architecture robuste** : Respecte l'architecture Proxmox au lieu de la combattre.

**Simplicité pragmatique** : Configuration directe des credentials sans complexité inutile.

**Workflow professionnel** : 6 phases automatisées avec vérifications complètes.

**Production-ready** : Testé en conditions réelles, gestion complète des erreurs.

**Documentation exhaustive** : Guides complets avec troubleshooting détaillé.

## [1.1.0] - 2025-11-07

### Nouvelle fonctionnalité - Cluster Proxmox VE

Ajout de la création automatisée de cluster Proxmox VE pour haute disponibilité.

### Ajouté

- **Cluster Proxmox VE**
  - Role Ansible `proxmox-cluster-create` complet
  - Playbook `create-proxmox-cluster.yml` pour automatisation
  - Support création cluster 2+ nœuds
  - Configuration automatique Corosync et quorum
  - Vérifications automatiques de santé du cluster
  - Synchronisation du Cluster Filesystem (CFS)
  - Gestion des erreurs et retry logic

- **Inventaire Cluster**
  - Fichier `proxmox-cluster.ini` pour configuration cluster
  - Support nœud primaire et nœuds secondaires
  - Variables configurables (nom cluster, timeouts, etc.)
  - Exemple d'inventaire avec documentation

- **Commandes Makefile**
  - `make test-cluster` - Tester connectivité nœuds cluster
  - `make create-cluster` - Créer le cluster automatiquement
  - `make cluster-status` - Afficher statut du cluster
  - `make cluster-nodes` - Lister les nœuds du cluster
  - `make cluster-health` - Vérification complète de santé
  - `make create-cluster-dry` - Simulation création cluster

- **Documentation Cluster**
  - Guide complet de création de cluster
  - Guide de dépannage spécifique au cluster
  - Exemples de configuration
  - Procédures de vérification et tests
  - Commandes de diagnostic
  - Résolution de problèmes courants

- **Fonctionnalités Cluster**
  - Vérifications pré-création (connectivité, Proxmox installé)
  - Création cluster sur nœud primaire
  - Jonction automatique des nœuds secondaires
  - Vérification quorum et synchronisation
  - Tests post-création automatiques
  - Support configurations 2+ nœuds

### Amélioré

- **README.md**
  - Section complète sur la création de cluster
  - Exemples d'utilisation des commandes cluster
  - Structure de projet mise à jour
  - Documentation enrichie

- **Ansible**
  - Makefile étendu avec commandes cluster
  - Help étendu pour inclure les nouvelles commandes

### Documentation

- Ajout de `docs/proxmox-cluster-creation.md` - Guide complet cluster
- Ajout de `docs/proxmox-cluster-troubleshooting.md` - Dépannage cluster
- Mise à jour README avec section cluster
- Exemples de configuration cluster

### Notes de version

**v1.1.0 - Fonctionnalités clés**

**Cluster automatisé** : Création de cluster Proxmox VE en une commande via Ansible.

**Haute disponibilité** : Support 2+ nœuds avec gestion automatique du quorum.

**Production-ready** : Vérifications complètes, gestion d'erreurs, retry logic.

**Documentation complète** : Guides détaillés avec exemples et dépannage.

## [1.0.0] - 2025-11-07

### Version initiale - Installation Proxmox VE

Première version du système d'installation automatisée de Proxmox VE.

### Ajouté

- **Installation Proxmox VE**
  - Playbook Ansible pour installation automatisée
  - Role `proxmox-install` complet
  - Support Proxmox VE 8.x sur Debian 12 (Bookworm)
  - Configuration réseau et hostname
  - Support standalone (pas de cluster requis)

- **Fix DHCPv6 Timeout**
  - Configuration automatique timeout DHCPv6 (10 secondes)
  - Évite les blocages de 15+ minutes pendant l'installation
  - Documentation du problème et solution

- **Ansible**
  - Inventaire pour serveurs Proxmox
  - Makefile avec commandes simplifiées
  - Templates pour configuration
  - Tests de connectivité pré-installation
  - Vérification post-installation

- **Terraform**
  - Configuration infrastructure S3 (AWS, MinIO, Wasabi, etc.)
  - Gestion bucket avec lifecycle policies
  - Versioning et chiffrement côté serveur
  - Configuration générique compatible tout fournisseur S3

- **Documentation**
  - Guide installation Proxmox VE
  - Guide dépannage installation
  - README complet
  - Configuration 100% générique

- **Configuration générique**
  - Compatible tous fournisseurs VPS (AWS, GCP, OVH, Hetzner, etc.)
  - Seules les adresses IP sont nécessaires
  - Pas de dépendances fournisseur spécifique
  - Templates avec placeholders génériques

### Sécurité

- Credentials dans fichiers example (jamais committés)
- Connexions SSH par clés
- Configuration sécurisée des permissions
- Variables sensibles marquées `sensitive` dans Terraform

### Infrastructure

- Support Proxmox VE 8.x
- Compatible Debian 12 (Bookworm)
- S3 compatible (AWS, MinIO, Wasabi, etc.)
- Architecture standalone ou cluster

## Notes de version

### v1.0.0 - Fonctionnalités clés

**Installation automatisée** : Déploiement Proxmox VE en une commande via Ansible.

**Fix DHCPv6** : Solution au problème de timeout DHCPv6 qui bloquait les installations.

**100% Générique** : Fonctionne avec n'importe quel fournisseur VPS, seules les IPs sont nécessaires.

**Terraform** : Infrastructure S3 as Code, compatible tous fournisseurs S3.

**Production-ready** : Testé sur VPS réels, gestion d'erreurs, documentation complète.

## Support

- Email : your-email@example.com
- Documentation : `docs/`
- Issues : GitHub

## Contributeurs

- Community

## Licence

MIT License - voir [LICENSE](LICENSE)
