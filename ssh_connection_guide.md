# Guide de Connexion SSH

Ce document fournit un guide rapide pour se connecter aux machines virtuelles (VMs) en utilisant SSH.

## Méthode 1: Connexion en 2 étapes (Manuelle)

Cette méthode est simple mais moins efficace pour un usage quotidien.

1.  **Connectez-vous d'abord à la VM proxy (le "jump host")** :
    ```bash
    ssh <user>@<IP_PUB_PROXY>
    # Exemple: ssh root@167.235.118.227
    ```

2.  **Depuis la session SSH du proxy, connectez-vous à une VM privée** :
    ```bash
    ssh <user>@<IP_PRIVEE_VM>
    # Exemple: ssh imane@192.168.100.10
    ```

## Méthode 2: Utilisation de `ProxyJump` (Recommandée)

Cette méthode est beaucoup plus directe et efficace. Elle nécessite une configuration unique dans votre fichier `~/.ssh/config` sur votre machine locale.

1.  **Modifiez ou créez le fichier `~/.ssh/config`** :
    ```
    # --- Fichier: ~/.ssh/config ---

    # Alias pour le Jump Host (Proxy)
    Host proxy-vm
        HostName 167.235.118.227
        User root  # Ou l'utilisateur que vous avez configuré

    # Configuration pour les VMs privées
    Host frontend-vm backend-vm database-vm
        User imane # Utilisateur commun pour les VMs privées
        ProxyJump proxy-vm # Indique à SSH de passer par 'proxy-vm'

    # Configuration spécifique si nécessaire
    Host frontend-vm
        HostName 192.168.100.10

    Host backend-vm
        HostName 192.168.100.20

    Host database-vm
        HostName 192.168.100.30
    ```

2.  **Connectez-vous directement à n'importe quelle VM privée** :
    Avec la configuration ci-dessus, vous pouvez maintenant taper directement :
    ```bash
    ssh frontend-vm  # Se connecte à 192.168.100.10 via le proxy
    ssh backend-vm   # Se connecte à 192.168.100.20 via le proxy
    ssh database-vm  # Se connecte à 192.168.100.30 via le proxy
    ```

SSH s'occupe automatiquement de la connexion au `proxy-vm` en arrière-plan et établit le tunnel vers la VM finale. C'est transparent pour vous. 