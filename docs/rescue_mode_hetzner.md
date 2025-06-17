# Procédure de Secours : Mode Rescue Hetzner pour Proxmox VE

Si votre serveur Proxmox VE devient inaccessible après une modification (en particulier réseau), le mode Rescue de Hetzner est votre principal outil de dépannage.

## 1. Activer le Mode Rescue

1.  Connectez-vous à votre console Hetzner Robot.
2.  Sélectionnez votre serveur.
3.  Allez dans l'onglet "Rescue".
4.  Choisissez un système d'exploitation (Debian est un bon choix) et une clé SSH publique pour l'accès.
5.  Activez le mode Rescue. Le serveur va redémarrer sur ce système temporaire. Notez le mot de passe root fourni s'il n'utilise pas de clé SSH.

## 2. Accéder au Serveur en Mode Rescue

Une fois le serveur redémarré en mode Rescue, connectez-vous en SSH avec l'utilisateur `root` et le mot de passe fourni (ou votre clé SSH).

```bash
ssh root@YOUR_SERVER_IP
```

## 3. Monter le Système de Fichiers Proxmox

Votre installation Proxmox se trouve sur les disques durs du serveur. Il faut la monter pour pouvoir modifier ses fichiers.

En général, les serveurs Hetzner avec Proxmox utilisent un RAID logiciel (mdadm).
Identifiez vos partitions RAID:
```bash
cat /proc/mdstat
lsblk -f
```
Supposons que votre partition racine `/` de Proxmox soit `/dev/md2` (adaptez si nécessaire) et que votre partition `/boot` soit `/dev/md1`.

Créez des points de montage et montez les partitions:
```bash
mkdir /mnt/proxmox
mount /dev/md2 /mnt/proxmox

# Si vous avez une partition /boot séparée (par exemple /dev/md1)
mkdir /mnt/proxmox/boot
mount /dev/md1 /mnt/proxmox/boot
```

## 4. Entrer dans l'Environnement Proxmox (chroot)

Pour exécuter des commandes comme si vous étiez dans votre système Proxmox, utilisez `chroot`:

```bash
mount -t proc /proc /mnt/proxmox/proc
mount -t sysfs /sys /mnt/proxmox/sys
mount -o bind /dev /mnt/proxmox/dev
mount -o bind /dev/pts /mnt/proxmox/dev/pts # Important pour certains outils
chroot /mnt/proxmox /bin/bash
```
À partir de maintenant, vous êtes "à l'intérieur" de votre système Proxmox.

## 5. Commandes Utiles en chroot

*   **Vérifier/Modifier la configuration réseau:**
    ```bash
    nano /etc/network/interfaces
    # Vérifiez aussi /etc/network/interfaces.d/
    ```
*   **Vérifier l'état des services:**
    ```bash
    systemctl status sshd
    systemctl status networking
    systemctl status pveproxy pvedaemon # Services Proxmox
    ```
*   **Vérifier les journaux système:**
    ```bash
    journalctl -xe
    journalctl -u sshd
    ```
*   **Reconstruire initramfs (si des modules kernel ont changé):**
    ```bash
    update-initramfs -u -k all
    ```
*   **Gérer les bootloaders Proxmox (si vous suspectez un problème de démarrage):**
    ```bash
    proxmox-boot-tool status
    proxmox-boot-tool refresh
    ```

## 6. Sortir du chroot et Redémarrer

Une fois les corrections apportées:
1.  Sortez du chroot: `exit`
2.  Démontez les systèmes de fichiers (ordre inverse du montage):
    ```bash
    umount /mnt/proxmox/dev/pts
    umount /mnt/proxmox/dev
    umount /mnt/proxmox/sys
    umount /mnt/proxmox/proc
    umount /mnt/proxmox/boot # Si monté
    umount /mnt/proxmox
    ```
3.  Redémarrez le serveur depuis le système Rescue: `reboot`

Le serveur devrait maintenant redémarrer sur votre installation Proxmox corrigée. N'oubliez pas de désactiver le mode Rescue depuis la console Hetzner si vous ne l'avez pas fait redémarrer sur le disque dur par défaut.
