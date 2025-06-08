# ansible-proxmox-dedicated

Playbook **Ansible** minimal pour installer **Proxmox VE 8** sur un serveur dédié Debian 12.

---

## Contenu du dépôt

```
ansible-proxmox-dedicated/
├── .env.example       # Variables d'environnement (exemple)
├── .gitignore         # Fichiers à ignorer
├── inventory.yml      # Configuration des serveurs
├── playbook.yml       # Playbook principal
├── roles/
│   └── proxmox/
│       ├── tasks/main.yml     # Tâches d'installation
│       └── templates/sources.list.j2  # Dépôt Proxmox
└── vars.yml           # Variables optionnelles
```

---

## Installation et configuration

### 1. Cloner le dépôt

```bash
git clone https://github.com/<utilisateur>/ansible-proxmox-dedicated.git
cd ansible-proxmox-dedicated
```

### 2. Configurer les variables d'environnement

```bash
# Copier le fichier d'exemple
cp .env.example .env

# Éditer avec vos vraies valeurs
nano .env
```

### 3. Lancer l'installation

```bash
# Charger les variables d'environnement
source .env

# Exécuter le playbook
ansible-playbook -i inventory.yml playbook.yml
```

> L'interface Proxmox sera ensuite accessible sur **https\://<IP>:8006**.

---

## Fichiers clés

### playbook.yml

```yaml
- hosts: proxmox
  become: true
  roles:
    - proxmox
```

### roles/proxmox/tasks/main.yml

```yaml
- apt:
    update_cache: yes
    upgrade: dist

- template:
    src: sources.list.j2
    dest: /etc/apt/sources.list.d/pve-install-repo.list

- apt_key:
    url: https://enterprise.proxmox.com/debian/proxmox-release-bookworm.gpg
    state: present

- apt:
    name:
      - proxmox-ve
      - postfix
      - open-iscsi
    state: present
    update_cache: yes

- lineinfile:
    path: /etc/apt/sources.list.d/pve-enterprise.list
    regexp: "^deb"
    state: absent

- reboot:
    msg: "Reboot after Proxmox install"
```

### inventory.yml (exemple)

```yaml
all:
  children:
    proxmox:
      hosts:
        proxmox_server:
          ansible_host: "{{ lookup('env', 'PROXMOX_IP') }}"
          ansible_user: "{{ lookup('env', 'PROXMOX_USER') }}"
          ansible_ssh_pass: "{{ lookup('env', 'PROXMOX_PASS') }}"
          ansible_python_interpreter: /usr/bin/python3
```

### .env.example

```bash
# Variables d'environnement pour Ansible Proxmox
PROXMOX_IP=votre_ip_serveur
PROXMOX_USER=root
PROXMOX_PASS=votre_mot_de_passe
```

---

## Sécurité

- ✅ Toutes les informations sensibles (IP, user, password) sont dans `.env`
- ✅ Le fichier `.env` est exclu du versioning via `.gitignore`
- ✅ Seul `.env.example` (sans vraies valeurs) est commité
- ⚠️ **Important** : Ne jamais commiter le fichier `.env` contenant vos vraies credentials

---

## Prérequis

- **Ansible** installé sur votre machine locale
- **Accès SSH** au serveur Debian 12 cible
- **Privilèges root** sur le serveur cible
