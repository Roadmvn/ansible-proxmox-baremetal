#!/bin/bash

# Script pour nettoyer les VMs créées par l'automatisation

# Variables
PLAYBOOK="playbooks/cleanup_vms.yml"
INVENTORY="hosts"

echo "Lancement du nettoyage des VMs..."

# Vérifier si l'inventaire existe
if [ ! -f "$INVENTORY" ]; then
    echo "Erreur : Fichier d'inventaire '$INVENTORY' non trouvé."
    exit 1
fi

# Vérifier si le playbook de nettoyage existe
if [ ! -f "$PLAYBOOK" ]; then
    echo "Erreur : Playbook de nettoyage '$PLAYBOOK' non trouvé."
    exit 1
fi

# Exécuter le playbook de nettoyage
ansible-playbook -i "$INVENTORY" "$PLAYBOOK" --extra-vars "vm_ids=[801, 802, 803, 804]"

echo "Nettoyage terminé." 