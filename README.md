# ansible-proxmox-dedicated

Playbook **Ansible** minimal pour installer **Proxmox VE 8** sur un serveur dédié Debian 12.

---

## Contenu du dépôt

```
ansible-proxmox-dedicated/
├── .gitignore         # Fichiers à ignorer
├── inventory.ini      # Adresse IP du serveur
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

### 2. Vérifier l'accès SSH
Assurez-vous que vous pouvez vous connecter au serveur en SSH :
```bash
# Connectez-vous une première fois pour accepter la clé du serveur
ssh root@VOTRE_IP_SERVEUR
```

### 3. Modifier l'inventaire
Éditez `inventory.ini` et remplacez l'IP par celle de votre serveur :
```ini
[proxmox]
VOTRE_IP_SERVEUR
```

### 4. Lancer l'installation
```bash
# Méthode 1: Mode interactif (recommandé pour un dépôt public)
ansible-playbook -i inventory.ini -u root -k -b playbook.yml

# Méthode 2: Spécifier le mot de passe en ligne de commande (attention aux logs)
ansible-playbook -i inventory.ini -u root -e "ansible_ssh_pass=VOTRE_MOT_DE_PASSE" playbook.yml
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
    regexp: '^deb'
    state: absent

- reboot:
    msg: "Reboot after Proxmox install"
```

### inventory.ini (exemple)

```ini
[proxmox]
VOTRE_IP_SERVEUR
```

---

## Sécurité

- ✅ Aucun credential n'est stocké dans le code
- ✅ Mot de passe demandé interactivement avec l'option `-k`
- ✅ Possibilité d'utiliser des clés SSH pour une meilleure sécurité
- ⚠️ **Important** : Ne jamais stocker de mots de passe dans votre dépôt, même dans les variables

---

## Prérequis

- **Ansible** installé sur votre machine locale
- **Accès SSH** au serveur Debian 12 cible
- **Privilèges root** sur le serveur cible
