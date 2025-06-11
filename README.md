# Ansible Proxmox Baremetal

Ce projet contient des playbooks Ansible pour installer et configurer Proxmox VE sur des serveurs bare-metal.

## Structure du projet

```
ansible-proxmox-baremetal/
├── inventory.yml                # Inventaire des serveurs
├── secret_vars.yml              # Variables sensibles (non versionnées)
├── secret_vars.example.yml      # Exemple de structure des variables sensibles
├── playbooks/
│   ├── main.yml                 # Playbook principal
│   ├── install_proxmox.yml      # Installation de Proxmox
│   ├── configure_network.yml    # Configuration réseau
│   └── standalone/              # Playbooks utilitaires/ponctuels
│       ├── create_vmbr1.yml     # Créer un bridge interne vmbr1
│       ├── destroy_vmbr1.yml    # Supprimer le bridge vmbr1
│       ├── test_vmbr1_vm.yml    # Créer une VM test sur vmbr1
│       └── templates/           # Templates pour les playbooks standalone
│           └── vmbr1.j2         # Template pour la configuration vmbr1
├── roles/
│   └── proxmox/
│       ├── tasks/
│       │   ├── main.yml
│       │   └── network.yml
│       └── templates/
│           └── proxmox_free_edition_repo.j2
├── .gitignore                   # Fichiers à ignorer
└── README.md
```

## Prérequis

- Ansible 2.9 ou supérieur
- Un serveur cible sous Debian 12 (Bookworm)
- Un accès SSH avec des privilèges sudo
- Pour les VM test : `ansible-galaxy collection install community.general`

## Configuration

### Variables sensibles

Avant d'utiliser ce projet, vous devez créer un fichier `secret_vars.yml` à partir de l'exemple fourni :

```bash
cp secret_vars.example.yml secret_vars.yml
nano secret_vars.yml  # Éditez avec vos propres valeurs
```

Le fichier contient les variables suivantes :

- `proxmox_host`: Adresse IP du serveur Proxmox
- `proxmox_user`: Nom d'utilisateur SSH
- `proxmox_password`: Mot de passe SSH
- `proxmox_api_password`: Mot de passe pour l'API Proxmox
- `vmbr1_ipaddr`: Adresse IP pour l'interface vmbr1
- `vmbr1_netmask`: Masque de sous-réseau pour vmbr1

**Note de sécurité**: Le fichier `secret_vars.yml` contient des informations sensibles et est exclu du versionnement via `.gitignore`.

## Utilisation

### Installation complète

```bash
ansible-playbook -i inventory.yml playbooks/main.yml
```

### Installation de Proxmox uniquement

```bash
ansible-playbook -i inventory.yml playbooks/install_proxmox.yml
```

### Configuration du réseau uniquement

```bash
ansible-playbook -i inventory.yml playbooks/configure_network.yml
```

### Utilitaires réseau

#### Créer un bridge interne vmbr1

```bash
ansible-playbook -i inventory.yml playbooks/standalone/create_vmbr1.yml
```

#### Tester le bridge avec une VM

```bash
# Créer une VM test avec l'ID par défaut (999)
ansible-playbook -i inventory.yml playbooks/standalone/test_vmbr1_vm.yml

# OU avec un ID personnalisé
ansible-playbook -i inventory.yml playbooks/standalone/test_vmbr1_vm.yml -e "vm_id=105"

# OU avec plusieurs paramètres personnalisés
ansible-playbook -i inventory.yml playbooks/standalone/test_vmbr1_vm.yml -e "vm_id=105 vm_name=demo-vm vm_memory=1024"
```

#### Supprimer le bridge vmbr1

```bash
ansible-playbook -i inventory.yml playbooks/standalone/destroy_vmbr1.yml
```

## Paramètres personnalisables en ligne de commande

Vous pouvez personnaliser certains paramètres sans modifier les playbooks en utilisant l'option `-e` (extra-vars) :

| Playbook          | Variable  | Description         | Valeur par défaut |
| ----------------- | --------- | ------------------- | ----------------- |
| test_vmbr1_vm.yml | vm_id     | ID de la VM test    | 999               |
| test_vmbr1_vm.yml | vm_name   | Nom de la VM test   | test-vmbr1        |
| test_vmbr1_vm.yml | vm_memory | Mémoire RAM (MB)    | 512               |
| test_vmbr1_vm.yml | vm_cores  | Nombre de cœurs CPU | 1                 |

Exemple :

```bash
ansible-playbook -i inventory.yml playbooks/standalone/test_vmbr1_vm.yml -e "vm_id=150 vm_memory=2048"
```

## Fonctionnalités

- Installation complète de Proxmox VE sur Debian 12
- Configuration d'une interface bridge vmbr1 pour les réseaux virtuels isolés
- Test de connectivité automatique des interfaces
- Création de VM de test pour valider la configuration
- Configuration sécurisée avec le dépôt community (sans abonnement)
- Playbooks réversibles pour un environnement propre

## Licence

[Licence à préciser]
