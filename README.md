# Déploiement Ansible Proxmox Baremetal pour Hetzner

Déploiement automatisé de Proxmox VE sur un serveur dédié Hetzner en utilisant Ansible.
Ce projet vise une configuration entièrement automatisée, incluant l'installation initiale de Proxmox, la configuration réseau sécurisée pour l'IP publique Hetzner, un pont privé optionnel, et des vérifications post-installation.

## Fonctionnalités (Nouvelle Structure)

*   **Playbooks Modulaires :**
    *   `00_install_proxmox.yml` : Installation de base de Proxmox VE sans modification du réseau.
    *   `01_safe_network_config.yml` : Configure `vmbr0` pour l'IP publique Hetzner (point-à-point /32) *après* un redémarrage réussi post-installation.
    *   `02_add_private_bridge.yml` : Ajoute optionnellement un pont privé `vmbr1` pour le réseau interne des VMs.
    *   `99_post_install_check.yml` : Effectue des vérifications de santé (kernel PVE, SSH, interface web Proxmox, uptime).
*   **Sécurité d'abord :**
    *   Redémarrage obligatoire et vérification de la connectivité SSH après l'installation de base avant d'appliquer les changements réseau critiques.
    *   Sauvegarde automatique de `/etc/network/interfaces` avant modification.
    *   Utilise `ifupdown` (pas de Netplan).
*   **Documentation :** Inclut un [Guide du Mode Rescue Hetzner](./docs/rescue_mode_hetzner.md).

## Prérequis

*   Ansible installé sur le nœud de contrôle.
*   `sshpass` installé sur le nœud de contrôle si vous utilisez initialement l'authentification par mot de passe (bien que les clés SSH soient fortement recommandées).
*   Un serveur dédié Hetzner avec Debian 12 (Bookworm) installé (ou une base Debian/Ubuntu compatible).
*   Accès SSH au serveur avec les privilèges root.

## Configuration Initiale

1.  **Clônez le dépôt :**
    ```bash
    git clone <url-de-votre-depot>
    cd ansible-proxmox-baremetal
    ```
2.  **Configurez l'Inventaire :**
    *   Copiez `inventory/hosts.ini.example` vers `inventory/hosts.ini` (si un exemple est fourni, sinon créez-le).
    *   Modifiez `inventory/hosts.ini` pour inclure l'adresse IP de votre serveur sous le groupe `[proxmox]` :
        ```ini
        [proxmox]
        votre_adresse_ip_serveur
        ```
3.  **Configurez les Variables :**
    *   Copiez `secret_vars.example.yml` vers `secret_vars.yml`.
    *   **IMPORTANT :** Modifiez `secret_vars.yml` et remplissez toutes les variables requises, notamment :
        *   `ansible_user` : (par ex., `root`)
        *   `ansible_ssh_pass` : Mot de passe root de votre serveur (envisagez d'utiliser Ansible Vault et les clés SSH pour la production).
        *   `proxmox_node` : Nom souhaité pour le nœud Proxmox (par ex., "pve1").
        *   `proxmox_hw_interface` : Interface réseau principale (par ex., "eth0").
        *   `proxmox_public_ip` : IP publique de votre serveur.
        *   `proxmox_public_gateway` : Passerelle publique de votre serveur (spécifique à Hetzner).
        *   (Optionnel, pour `02_add_private_bridge.yml`)
            *   `proxmox_vmbr1_ip` : (par ex., "192.168.100.1")
            *   `proxmox_vmbr1_cidr` : (par ex., "24")
            *   `proxmox_vmbr1_bridge_ports` : (par ex., "none" ou une interface physique)
    *   **Sécurité :** Il est fortement recommandé de chiffrer `secret_vars.yml` en utilisant Ansible Vault :
        ```bash
        ansible-vault encrypt secret_vars.yml
        ```
        Un mot de passe pour le coffre-fort (vault) vous sera demandé.

## Utilisation

Exécutez les playbooks séquentiellement. Si vous utilisez Ansible Vault, ajoutez `--ask-vault-pass` à vos commandes.

1.  **Installez Proxmox VE (inclut un redémarrage) :**
    ```bash
    ansible-playbook playbooks/00_install_proxmox.yml -i inventory/hosts.ini --extra-vars "@secret_vars.yml"
    ```
2.  **Configurez le Pont Réseau Public (vmbr0) :**
    *(Exécutez ceci uniquement après que `00_install_proxmox.yml` s'est terminé avec succès, y compris le redémarrage et la reconnexion SSH).*
    ```bash
    ansible-playbook playbooks/01_safe_network_config.yml -i inventory/hosts.ini --extra-vars "@secret_vars.yml"
    ```
3.  **(Optionnel) Ajoutez un Pont Réseau Privé (vmbr1) :**
    ```bash
    ansible-playbook playbooks/02_add_private_bridge.yml -i inventory/hosts.ini --extra-vars "@secret_vars.yml"
    ```
4.  **Exécutez les Vérifications Post-Installation :**
    ```bash
    ansible-playbook playbooks/99_post_install_check.yml -i inventory/hosts.ini --extra-vars "@secret_vars.yml"
    ```

---

## 🔒 Sécurité & Bonnes Pratiques Opérationnelles

### Avant les Modifications Réseau Critiques (par ex., `01_safe_network_config.yml`) :

*   **[ ] Vérification du Kernel :** Assurez-vous que le playbook `00_install_proxmox.yml` s'est terminé et que le serveur a redémarré sur un **kernel PVE**. Le playbook `01_safe_network_config.yml` inclut une assertion pour cela.
*   **[ ] Accès SSH Confirmé :** Vous pouvez vous connecter en SSH au serveur utilisant le kernel PVE de Proxmox *avant* d'exécuter la configuration réseau.
*   **[ ] Sauvegarde de la Configuration Réseau :** Le playbook `01_safe_network_config.yml` sauvegarde automatiquement `/etc/network/interfaces` dans `/root/interfaces.backup-{{timestamp}}`. Vérifiez ceci si vous avez des inquiétudes.
*   **[ ] Console Hetzner Prête :** Ayez la console Robot Hetzner (ou l'accès KVM) ouverte et prête. Si l'accès SSH est perdu après les modifications réseau, ce sera votre moyen de récupération. Référez-vous au [Guide du Mode Rescue Hetzner](./docs/rescue_mode_hetzner.md).

### OpSec Général :

*   **Ansible Vault :** Chiffrez toujours les fichiers contenant des données sensibles (comme `secret_vars.yml`) en utilisant `ansible-vault`.
*   **Clés SSH :** Donnez la priorité à l'authentification par clé SSH plutôt qu'aux mots de passe. Désactivez la connexion root par mot de passe sur votre serveur une fois l'authentification par clé configurée.
*   **Pare-feu :** Configurez le pare-feu Hetzner (dans la console Robot) et `ferm` (ou `iptables/nftables`) sur Proxmox VE lui-même pour limiter l'accès aux ports nécessaires (SSH : 22, Web Proxmox : 8006, etc.).
*   **Sauvegardes Régulières :** Mettez en œuvre une stratégie de sauvegarde robuste pour la configuration de votre hôte Proxmox VE et vos VMs.

---

## Aperçu du Pontage Réseau (Spécifique à Hetzner)

Cette configuration met en place `vmbr0` pour l'accès internet public et optionnellement `vmbr1` pour un réseau privé.

**Flux Simplifié :**

```
                                VMs (sur vmbr0 ou vmbr1)
                                 ^       ^
                                 |       |
 Réseau Externe --- [eth0] --- [vmbr0 (IP Publique)] --- Hôte Proxmox
 (Internet)                      ^
                                 | (Réseau Privé Optionnel)
                                 + --- [vmbr1 (IPs Privées)] --- VMs
```

*   **`eth0` (Interface Physique) :** Se connecte au réseau Hetzner. N'est pas directement assignée à une IP dans la configuration finale.
*   **`vmbr0` (Pont Public) :**
    *   Détient l'adresse IP publique principale du serveur (par ex., `167.235.118.227/32`).
    *   Utilise une configuration `pointopoint` avec la passerelle Hetzner pour router correctement le trafic pour l'unique IP publique.
    *   Les VMs nécessitant un accès public direct (par ex., avec des IPs publiques additionnelles de Hetzner) seraient typiquement attachées ici.
*   **`vmbr1` (Pont Privé Optionnel) :**
    *   Utilise une plage d'IP privée (par ex., `192.168.100.1/24`).
    *   Utilisé pour les VMs qui ont seulement besoin de communiquer entre elles ou d'accéder à internet via NAT/routage à travers l'hôte Proxmox (si configuré).
    *   Typiquement `bridge_ports none` à moins que vous n'ayez une interface physique dédiée pour un LAN privé.

