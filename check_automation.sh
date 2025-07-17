#!/bin/bash

# Script pour vérifier l'état de l'automatisation (VMs créées, connectivité, etc.)

echo "Vérification de l'état des VMs sur Proxmox..."

# Utiliser qm list pour voir les VMs et leur état
ssh root@<IP_PROXMOX> "qm list"

echo "---------------------------------------------"
echo "Vérification de la connectivité..."

# Ping vers la VM publique (proxy)
echo "Ping vers proxy-vm (167.235.118.227)..."
ping -c 3 167.235.118.227

# Test de connexion SSH via le jump host vers les VMs privées
JUMP_HOST="root@167.235.118.227"
PRIVATE_VMS=("imane@192.168.100.10" "imane@192.168.100.20" "imane@192.168.100.30")

for vm in "${PRIVATE_VMS[@]}"; do
    echo "---------------------------------------------"
    echo "Test de connexion SSH à $vm via le jump host..."
    ssh -J "$JUMP_HOST" "$vm" "echo 'Connexion réussie à $(hostname)'"
done

echo "Vérification terminée." 