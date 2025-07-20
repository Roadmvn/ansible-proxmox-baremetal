#!/bin/bash
# ==============================================================================
# SCRIPT DE CONFIGURATION IP STATIQUE POUR VMs PROXMOX
# Auteur: Tudy Gbaguidi
#
# A exécuter directement sur le serveur Proxmox en tant que root.
# Ce script configure les adresses IP statiques des VMs privées.
# ==============================================================================

# -- Ne pas modifier --
set -e # Arrête le script si une commande échoue
trap 'echo "ERREUR: Une commande a échoué à la ligne $LINENO. Arrêt."; exit 1' ERR

# --- Configuration des VMs à modifier ---
declare -A VMS=(
    # VMID="NOM:IP_STATIQUE:PASSERELLE"
    ["802"]="frontend-vm:10.0.1.10/24:10.0.1.1"
    ["803"]="backend-vm:10.0.1.20/24:10.0.1.1"
    ["804"]="database-vm:10.0.1.30/24:10.0.1.1"
)

# --- Fonction principale pour configurer une VM ---
configure_vm() {
    local VMID=$1
    local NAME
    local IP
    local GATEWAY
    IFS=':' read -r NAME IP GATEWAY <<< "${VMS[$VMID]}"

    echo "====================================================="
    echo ">> Début de la configuration pour $NAME (VM $VMID)"
    echo "====================================================="

    # 1. Vérifier si la VM est en cours d'exécution
    echo "  [1/5] Vérification du statut de la VM..."
    if ! qm status $VMID | grep -q "status: running"; then
        echo "  > ERREUR: La VM $NAME n'est pas démarrée. Veuillez la démarrer avant de lancer le script."
        return 1
    fi
    echo "  > VM en cours d'exécution."

    # 2. Attendre que l'agent QEMU soit disponible (crucial)
    echo "  [2/5] Attente de l'agent QEMU (max 2 minutes)..."
    local agent_timeout=24 # 24 tentatives * 5 secondes = 120 secondes
    local count=0
    until qm guest exec $VMID -- /bin/true >/dev/null 2>&1; do
        count=$((count + 1))
        if [ $count -ge $agent_timeout ]; then
            echo "  > ERREUR: L'agent QEMU pour la VM $NAME n'a pas répondu après 2 minutes."
            echo "  > Problème possible: l'agent n'est pas installé ou le réseau est complètement bloqué."
            echo "  > Commande pour installer l'agent (via la console): sudo apt update && sudo apt install qemu-guest-agent -y"
            return 1
        fi
        echo -n "." # Affiche un point à chaque tentative
        sleep 5
    done
    echo "" # Retour à la ligne après les points
    echo "  > Agent QEMU prêt !"

    # 3. Créer la configuration Netplan
    echo "  [3/5] Préparation de la configuration IP statique..."
    local netplan_config
    netplan_config=$(cat <<EOF
network:
  version: 2
  ethernets:
    ens18:
      dhcp4: no
      addresses: [$IP]
      gateway4: $GATEWAY
      nameservers:
        addresses: [1.1.1.1, 8.8.8.8]
EOF
)
    echo "  > Configuration pour $IP prête."

    # 4. Injecter la configuration dans la VM
    echo "  [4/5] Injection de la configuration via l'agent..."
    # Sauvegarde de l'ancienne configuration
    qm guest exec $VMID -- cp /etc/netplan/50-cloud-init.yaml /etc/netplan/50-cloud-init.yaml.bak_$(date +%F_%T) >/dev/null 2>&1 || true
    # Écriture de la nouvelle configuration
    qm guest exec $VMID -- /bin/bash -c "echo -e \"${netplan_config}\" > /etc/netplan/50-cloud-init.yaml"
    # Application
    qm guest exec $VMID -- netplan apply
    echo "  > Configuration appliquée dans la VM."

    # 5. Vérifier la connectivité
    echo "  [5/5] Test de la connectivité vers la passerelle..."
    sleep 5 # Laisser le temps au réseau de se stabiliser
    if qm guest exec $VMID -- ping -c 3 $GATEWAY >/dev/null 2>&1; then
        echo "  > SUCCÈS: La VM $NAME (IP: $IP) peut joindre la passerelle $GATEWAY."
    else
        echo "  > ERREUR: La connectivité a échoué. Vérifiez la configuration manuellement via 'qm terminal $VMID'."
        return 1
    fi
}

# --- Exécution pour chaque VM ---
for VMID in "${!VMS[@]}"; do
    configure_vm "$VMID"
done

echo ""
echo "====================================================="
echo "SCRIPT TERMINÉ AVEC SUCCÈS !"
echo "Toutes les VMs ont été configurées."
echo "=====================================================" 