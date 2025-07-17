# Guide de création d'une VM via SSH (`create_single_vm.yml`)

Ce document explique le fonctionnement de la tâche `playbooks/tasks/create_single_vm.yml`, qui est au cœur de la création de chaque VM. L'approche utilise des commandes `qm` (QEMU Manager) exécutées via une connexion SSH à l'hôte Proxmox.

## Étapes du processus

Le playbook exécute une série de commandes pour chaque VM définie dans `vm_config.example.yml`.

1.  **Vérification du Template**
    -   **Commande** : `pvesh get ...`
    -   **Action** : Avant de commencer, le script vérifie si le template Cloud-Init spécifié (ex: `ubuntu-2204-cloudinit-template`) existe bien sur le stockage Proxmox. Si ce n'est pas le cas, le processus s'arrête avec une erreur pour éviter des échecs en cours de route.

2.  **Création de la VM (`qm create`)**
    -   **Commande** : `qm create <vmid> --name ... --memory ... --cores ... --net0 ...`
    -   **Action** : Crée une nouvelle VM vide avec les caractéristiques de base (VMID, nom, RAM, CPU) et attache une interface réseau au pont spécifié (`vmbr0` ou `vmbr1`).

3.  **Importation du Disque (`qm importdisk`)**
    -   **Commande** : `qm importdisk <vmid> <template_name> <storage>`
    -   **Action** : Clone le disque du template Cloud-Init et le rend disponible comme un nouveau disque pour la VM qui vient d'être créée. Ce disque contient le système d'exploitation de base.

4.  **Attachement du Disque (`qm set --scsi0 ...`)**
    -   **Commande** : `qm set <vmid> --scsi0 <storage>:vm-<vmid>-disk-0`
    -   **Action** : Attache le disque fraîchement importé à la VM en tant que disque de démarrage principal (`scsi0`).

5.  **Configuration du Boot (`qm set --boot ...`)**
    -   **Commande** : `qm set <vmid> --boot c --bootdisk scsi0`
    -   **Action** : Configure la VM pour qu'elle démarre sur le disque (`c`) qui vient d'être attaché (`scsi0`).

6.  **Activation de l'Agent QEMU (`qm set --agent ...`)**
    -   **Commande** : `qm set <vmid> --agent enabled=1`
    -   **Action** : Active l'agent QEMU Guest. C'est crucial pour que Proxmox puisse obtenir des informations de la VM (comme son adresse IP) et exécuter certaines actions correctement.

7.  **Configuration Réseau via Cloud-Init (`qm set --ipconfig0 ...`)**
    -   **Commande** : `qm set <vmid> --ipconfig0 ip=<ip_address>,gw=<gateway>`
    -   **Action** : C'est ici que la magie de Cloud-Init opère. Cette commande passe la configuration réseau (adresse IP et passerelle) directement à Cloud-Init. Au premier démarrage, la VM lira cette configuration et l'appliquera automatiquement.

8.  **Démarrage de la VM (`qm start`)**
    -   **Commande** : `qm start <vmid>`
    -   **Action** : Démarre la VM. Le processus est terminé.

Cette méthode est robuste, rapide et ne dépend pas de l'API Proxmox, ce qui peut simplifier l'authentification (une simple connexion SSH suffit). 