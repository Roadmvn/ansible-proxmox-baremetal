# Configuration Réseau sur Proxmox

Ce document explique la configuration réseau requise sur le serveur Proxmox pour que l'automatisation fonctionne correctement.

## Interfaces Réseau

Nous utilisons deux ponts Linux (`Linux Bridge`) sur Proxmox :

1.  **`vmbr0` (Réseau Public)**
    -   **Objectif** : Connecter des VMs directement à Internet.
    -   **Configuration** : Ce pont est généralement configuré lors de l'installation de Proxmox et est lié à l'interface physique principale du serveur (par exemple, `enp0s31f6`). Il détient l'adresse IP publique principale du serveur baremetal.
    -   **Utilisation dans ce projet** : La `proxy-vm` est connectée à ce pont pour obtenir son adresse IP publique et être accessible depuis l'extérieur.

2.  **`vmbr1` (Réseau Privé)**
    -   **Objectif** : Créer un réseau local isolé pour les communications inter-VMs.
    -   **Configuration** : Ce pont n'est pas lié à une interface physique. Il fonctionne comme un switch virtuel.
        -   **Adresse IP** : Nous lui assignons une adresse IP statique qui servira de passerelle pour les VMs de ce réseau.
        -   **Exemple de configuration dans `/etc/network/interfaces` sur Proxmox** :
            ```
            auto vmbr1
            iface vmbr1 inet static
                address 192.168.100.1/24
                bridge-ports none
                bridge-stp off
                bridge-fd 0
            ```
    -   **Utilisation dans ce projet** : Les VMs `frontend-vm`, `backend-vm`, et `database-vm` sont connectées exclusivement à ce pont. La `proxy-vm` y est également connectée pour pouvoir communiquer avec elles.

## Plan d'adressage IP

-   **Serveur Proxmox (sur `vmbr1`)** : `192.168.100.1` (Sert de passerelle par défaut)
-   **Proxy VM (sur `vmbr1`)** : L'IP est gérée par la connexion au réseau public, mais elle communique sur le `192.168.100.0/24`.
-   **Frontend VM** : `192.168.100.10`
-   **Backend VM** : `192.168.100.20`
-   **Database VM** : `192.168.100.30`

Ce plan est défini dans le fichier `vm_config.example.yml` et est appliqué aux VMs via Cloud-Init lors de leur création. 