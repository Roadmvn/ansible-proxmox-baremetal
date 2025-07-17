# Guide Post-Création des VMs

Une fois que le script `run_automation.sh` a terminé avec succès, voici les étapes recommandées pour vérifier que tout fonctionne comme prévu.

## 1. Vérifier l'état des VMs sur Proxmox

Connectez-vous à votre interface web Proxmox ou utilisez la commande suivante en SSH sur le serveur Proxmox pour vous assurer que les 4 VMs sont en cours d'exécution (`running`).

```bash
qm list
```
Vous devriez voir les VMs 801, 802, 803, et 804 avec le statut "running".

## 2. Vérifier la connectivité

Le script `check_automation.sh` est conçu pour automatiser ces tests.

```bash
./check_automation.sh
```

Ce script effectue les actions suivantes :
- **Ping vers la VM publique** (`proxy-vm`).
- **Test de connexion SSH** à toutes les VMs privées en utilisant la `proxy-vm` comme "jump host".

### Comment se connecter manuellement ?

#### A. Connexion au Jump Host (Proxy VM)

```bash
ssh root@167.235.118.227
```
*(Remplacez `root` par l'utilisateur configuré dans votre template, par exemple `imane`).*

#### B. Connexion aux VMs privées depuis le Jump Host

Une fois connecté à la `proxy-vm`, vous pouvez atteindre les autres VMs :

```bash
# Depuis la proxy-vm
ssh imane@192.168.100.10  # Frontend
ssh imane@192.168.100.20  # Backend
ssh imane@192.168.100.30  # Database
```

#### C. Connexion directe via Jump Host (méthode recommandée)

Configurez votre fichier `~/.ssh/config` local comme suit pour simplifier les connexions :

```
Host proxy-vm
    HostName 167.235.118.227
    User root

Host frontend-vm
    HostName 192.168.100.10
    User imane
    ProxyJump proxy-vm

Host backend-vm
    HostName 192.168.100.20
    User imane
    ProxyJump proxy-vm

Host database-vm
    HostName 192.168.100.30
    User imane
    ProxyJump proxy-vm
```

Avec cette configuration, vous pouvez simplement faire :

```bash
ssh frontend-vm
ssh backend-vm
# etc.
```

## 3. Prochaines Étapes

- **Sécuriser vos VMs** : Changez les mots de passe par défaut, configurez des pare-feux (`ufw`), etc.
- **Déployer vos applications**.
- **Mettre en place un reverse proxy** (par exemple Nginx) sur la `proxy-vm` pour exposer vos services web. 