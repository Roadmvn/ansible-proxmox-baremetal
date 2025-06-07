# ansible-proxmox-dedicated

Playbook **Ansible** minimal pour installer **Proxmox VE 8** sur un serveur dédié Debian 12.

---

## Contenu du dépôt

```
ansible-proxmox-dedicated/
├── inventory.ini      # Adresse IP du serveur
├── playbook.yml       # Playbook principal
├── roles/
│   └── proxmox/
│       ├── tasks/main.yml     # Tâches d'installation
│       └── templates/sources.list.j2  # Dépôt Proxmox
└── vars.yml           # Variables optionnelles
```

---

## Utilisation rapide

```bash
# 1. Cloner le dépôt
$ git clone https://github.com/<utilisateur>/ansible-proxmox-dedicated.git
$ cd ansible-proxmox-dedicated

# 2. Éditer inventory.ini (IP du serveur dédié)

# 3. Lancer le playbook
$ ansible-playbook -i inventory.ini playbook.yml
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
167.235.118.227 ansible_user=root ansible_python_interpreter=/usr/bin/python3
``` 