#!/bin/bash

# Script pour lancer l'automatisation de la création des VMs

# Variables (peut être externalisé)
PLAYBOOK="playbooks/create_vms_ssh.yml"
INVENTORY="hosts"

echo "Lancement de l'automatisation de la création des VMs..."

# Vérifier si l'inventaire existe
if [ ! -f "$INVENTORY" ]; then
    echo "Erreur : Fichier d'inventaire '$INVENTORY' non trouvé."
    exit 1
fi

# Vérifier si le playbook existe
if [ ! -f "$PLAYBOOK" ]; then
    echo "Erreur : Playbook '$PLAYBOOK' non trouvé."
    exit 1
fi

# Exécuter le playbook Ansible
ansible-playbook -i "$INVENTORY" "$PLAYBOOK"

echo "Automatisation terminée." 