#!/bin/bash

# ============================================
# SCRIPT SETUP INTERACTIF - Ansible
# ============================================

set -euo pipefail

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Setup Ansible - Inter-Gestion${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Répertoire ansible
ANSIBLE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# ============================================
# CHOIX ENVIRONNEMENT
# ============================================
echo -e "${YELLOW}Environnement de déploiement :${NC}"
echo "1) Test (1 nœud)"
echo "2) Production (3 nœuds)"
read -p "Choisir [1-2]: " ENV_CHOICE

case $ENV_CHOICE in
    1)
        INVENTORY_FILE="$ANSIBLE_DIR/inventory/test.ini"
        echo -e "${GREEN}Mode TEST sélectionné${NC}"
        ;;
    2)
        INVENTORY_FILE="$ANSIBLE_DIR/inventory/production.ini"
        echo -e "${GREEN}Mode PRODUCTION sélectionné${NC}"
        ;;
    *)
        echo -e "${RED}Choix invalide${NC}"
        exit 1
        ;;
esac

# ============================================
# CONFIGURATION NŒUDS
# ============================================
echo ""
echo -e "${YELLOW}Configuration des nœuds :${NC}"

if [ "$ENV_CHOICE" = "1" ]; then
    read -p "IP du nœud test: " NODE1_IP
    read -p "Nom du nœud [node1]: " NODE1_NAME
    NODE1_NAME=${NODE1_NAME:-node1}

    # Mise à jour inventory test
    cat > "$INVENTORY_FILE" << EOF
[proxmox_test]
$NODE1_NAME ansible_host=$NODE1_IP ansible_user=root node_name=$NODE1_NAME config_backup_offset=0

[proxmox_test:vars]
ansible_ssh_private_key_file=~/.ssh/id_rsa
ansible_python_interpreter=/usr/bin/python3
base_dir=/opt/ig-infra-as-code
EOF
else
    read -p "IP nœud 1: " NODE1_IP
    read -p "IP nœud 2: " NODE2_IP
    read -p "IP nœud 3: " NODE3_IP

    # Mise à jour inventory production
    cat > "$INVENTORY_FILE" << EOF
[proxmox_cluster]
node1 ansible_host=$NODE1_IP ansible_user=root node_name=node1 config_backup_offset=0
node2 ansible_host=$NODE2_IP ansible_user=root node_name=node2 config_backup_offset=20
node3 ansible_host=$NODE3_IP ansible_user=root node_name=node3 config_backup_offset=40

[proxmox_cluster:vars]
ansible_ssh_private_key_file=~/.ssh/id_rsa
ansible_python_interpreter=/usr/bin/python3
base_dir=/opt/ig-infra-as-code
EOF
fi

echo -e "${GREEN}✓ Inventaire configuré${NC}"

# ============================================
# CONFIGURATION PASSWORDS
# ============================================
echo ""
echo -e "${YELLOW}Configuration des passwords :${NC}"

read -sp "Password Kopia (chiffrement): " KOPIA_PASS
echo ""
read -sp "Password Email SMTP: " SMTP_PASS
echo ""
read -p "Email utilisateur [infrastructure@inter-gestion.com]: " SMTP_USER
SMTP_USER=${SMTP_USER:-infrastructure@inter-gestion.com}

# Mise à jour group_vars/all.yml
sed -i.bak "s/CHANGEZ_MOI_PASSWORD_FORT_KOPIA/$KOPIA_PASS/" "$ANSIBLE_DIR/group_vars/all.yml"
sed -i.bak "s/CHANGEZ_MOI_PASSWORD_EMAIL/$SMTP_PASS/" "$ANSIBLE_DIR/group_vars/all.yml"
sed -i.bak "s/infrastructure@inter-gestion.com/$SMTP_USER/g" "$ANSIBLE_DIR/group_vars/all.yml"

rm -f "$ANSIBLE_DIR/group_vars/all.yml.bak"

echo -e "${GREEN}✓ Passwords configurés${NC}"

# ============================================
# TEST CONNECTIVITÉ
# ============================================
echo ""
echo -e "${YELLOW}Test de connectivité SSH...${NC}"

cd "$ANSIBLE_DIR"
if ansible all -i "$INVENTORY_FILE" -m ping > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Connectivité OK${NC}"
else
    echo -e "${RED}✗ Échec de connexion${NC}"
    echo "Vérifiez :"
    echo "  - IPs correctes"
    echo "  - Clés SSH configurées : ssh-copy-id root@$NODE1_IP"
    echo "  - Firewall autorise SSH"
    exit 1
fi

# ============================================
# RÉSUMÉ
# ============================================
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}CONFIGURATION TERMINÉE${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Inventaire : $INVENTORY_FILE"
echo "Variables  : $ANSIBLE_DIR/group_vars/all.yml"
echo ""
echo -e "${YELLOW}Prochaines étapes :${NC}"
if [ "$ENV_CHOICE" = "1" ]; then
    echo "  make deploy-test    # Déployer sur le nœud test"
else
    echo "  make deploy         # Déployer sur tous les nœuds"
fi
echo "  make test           # Tester la connectivité"
echo "  make health         # Vérifier la santé système"
echo ""
