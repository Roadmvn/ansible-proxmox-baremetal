# Architecture de Déploiement

Ce document décrit l'architecture cible des machines virtuelles (VMs) déployées par ce projet d'automatisation.

## Schéma de l'architecture

```
+--------------------------------------------------+
|                Serveur Proxmox VE                |
|               (Hetzner Baremetal)                |
|                                                  |
|  +----------------------+  +-------------------+  |
|  |      Internet        |  |   Réseau Privé    |  |
|  | (vmbr0 - Public IP)  |  | (vmbr1 - 192.168.100.0/24) |
|  +----------+-----------+  +---------+---------+  |
|             |                       |            |
|     +-------v-------+       +-------v-------+    |
|     |  Proxy VM     |       | Frontend VM   |    |
|     | (801)         |<----->| (802)         |    |
|     | 167.235.118.227 |       | 192.168.100.10  |    |
|     +---------------+       +-------+-------+    |
|        (Jump Host)                  |            |
|                               +-------v-------+    |
|                               | Backend VM    |    |
|                               | (803)         |    |
|                               | 192.168.100.20  |    |
|                               +-------+-------+    |
|                                       |            |
|                               +-------v-------+    |
|                               | Database VM   |    |
|                               | (804)         |    |
|                               | 192.168.100.30  |    |
|                               +---------------+    |
+--------------------------------------------------+
```

## Description des VMs

1.  **Proxy VM (`proxy-vm`)**
    -   **VMID** : 801
    -   **Réseau** : Connectée à `vmbr0` (public) et `vmbr1` (privé).
    -   **Rôle** : Sert de bastion ou "jump host" pour accéder aux VMs privées. C'est le seul point d'entrée SSH depuis l'extérieur. Elle peut aussi servir de reverse proxy pour exposer des services web.

2.  **Frontend VM (`frontend-vm`)**
    -   **VMID** : 802
    -   **Réseau** : Connectée uniquement à `vmbr1` (privé).
    -   **Rôle** : Héberge l'application frontend. N'est pas directement accessible depuis Internet.

3.  **Backend VM (`backend-vm`)**
    -   **VMID** : 803
    -   **Réseau** : Connectée uniquement à `vmbr1` (privé).
    -   **Rôle** : Héberge l'application backend / API.

4.  **Database VM (`database-vm`)**
    -   **VMID** : 804
    -   **Réseau** : Connectée uniquement à `vmbr1` (privé).
    -   **Rôle** : Héberge la base de données. C'est la couche la plus isolée de l'architecture.

## Flux de communication

-   **Accès administrateur** : L'administrateur se connecte en SSH à la `Proxy VM`. Depuis cette VM, il peut ensuite se connecter en SSH aux autres VMs du réseau privé.
-   **Trafic applicatif** : Les requêtes des utilisateurs arrivent sur la `Proxy VM` (si configurée en reverse proxy), qui les redirige vers la `Frontend VM`. Le frontend communique ensuite avec le backend, qui lui-même interroge la base de données. 