#!/bin/bash

# ============================================
# SCRIPT VÉRIFICATION PRÉ-DÉPLOIEMENT
# ============================================

set -euo pipefail

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

ANSIBLE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Vérification Pré-Déploiement${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

ERRORS=0
WARNINGS=0

# ============================================
# CHECK 1: Outils requis
# ============================================
echo -e "${YELLOW}[1/6] Vérification des outils...${NC}"

for cmd in ansible ansible-playbook terraform git; do
    if command -v $cmd &> /dev/null; then
        echo -e "  ${GREEN}✓${NC} $cmd installé"
    else
        echo -e "  ${RED}✗${NC} $cmd manquant"
        ((ERRORS++))
    fi
done

# ============================================
# CHECK 2: Fichiers de configuration
# ============================================
echo ""
echo -e "${YELLOW}[2/6] Vérification des fichiers...${NC}"

if [ -f "$ANSIBLE_DIR/group_vars/all.yml" ]; then
    echo -e "  ${GREEN}✓${NC} group_vars/all.yml existe"

    # Vérifier les passwords
    if grep -q "CHANGEZ_MOI" "$ANSIBLE_DIR/group_vars/all.yml"; then
        echo -e "  ${YELLOW}⚠${NC}  Passwords non configurés dans all.yml"
        ((WARNINGS++))
    fi
else
    echo -e "  ${RED}✗${NC} group_vars/all.yml manquant"
    ((ERRORS++))
fi

if [ -f "$ANSIBLE_DIR/inventory/hosts.ini" ]; then
    echo -e "  ${GREEN}✓${NC} inventory/hosts.ini existe"

    # Vérifier les IPs
    if grep -q "VOTRE_IP" "$ANSIBLE_DIR/inventory/hosts.ini"; then
        echo -e "  ${YELLOW}⚠${NC}  IPs non configurées dans hosts.ini"
        ((WARNINGS++))
    fi
else
    echo -e "  ${RED}✗${NC} inventory/hosts.ini manquant"
    ((ERRORS++))
fi

# ============================================
# CHECK 3: Clés SSH
# ============================================
echo ""
echo -e "${YELLOW}[3/6] Vérification clés SSH...${NC}"

if [ -f ~/.ssh/id_rsa ]; then
    echo -e "  ${GREEN}✓${NC} Clé SSH trouvée"
else
    echo -e "  ${YELLOW}⚠${NC}  Aucune clé SSH ~/.ssh/id_rsa"
    ((WARNINGS++))
fi

# ============================================
# CHECK 4: Connectivité (si configuré)
# ============================================
echo ""
echo -e "${YELLOW}[4/6] Test de connectivité...${NC}"

if ! grep -q "VOTRE_IP" "$ANSIBLE_DIR/inventory/hosts.ini" 2>/dev/null; then
    cd "$ANSIBLE_DIR"
    if ansible all -m ping &> /dev/null; then
        echo -e "  ${GREEN}✓${NC} Connectivité OK"
    else
        echo -e "  ${RED}✗${NC} Échec connexion aux nœuds"
        ((ERRORS++))
    fi
else
    echo -e "  ${YELLOW}⊘${NC}  IPs non configurées, skip"
fi

# ============================================
# CHECK 5: Structure Ansible
# ============================================
echo ""
echo -e "${YELLOW}[5/6] Vérification structure Ansible...${NC}"

REQUIRED_ROLES=("common" "kopia" "proxmox-backup")
for role in "${REQUIRED_ROLES[@]}"; do
    if [ -d "$ANSIBLE_DIR/roles/$role" ]; then
        echo -e "  ${GREEN}✓${NC} Role $role existe"
    else
        echo -e "  ${RED}✗${NC} Role $role manquant"
        ((ERRORS++))
    fi
done

# ============================================
# CHECK 6: Syntaxe playbooks
# ============================================
echo ""
echo -e "${YELLOW}[6/6] Vérification syntaxe playbooks...${NC}"

if [ -d "$ANSIBLE_DIR/playbooks" ]; then
    for playbook in "$ANSIBLE_DIR/playbooks"/*.yml; do
        if [ -f "$playbook" ]; then
            if ansible-playbook --syntax-check "$playbook" &> /dev/null; then
                echo -e "  ${GREEN}✓${NC} $(basename $playbook) syntaxe OK"
            else
                echo -e "  ${RED}✗${NC} $(basename $playbook) erreur syntaxe"
                ((ERRORS++))
            fi
        fi
    done
fi

# ============================================
# RÉSUMÉ
# ============================================
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}RÉSUMÉ${NC}"
echo -e "${GREEN}========================================${NC}"

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✓ Tout est OK ! Prêt pour le déploiement${NC}"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠ $WARNINGS avertissement(s)${NC}"
    echo -e "${GREEN}Vous pouvez déployer, mais vérifiez les avertissements${NC}"
    exit 0
else
    echo -e "${RED}✗ $ERRORS erreur(s) trouvée(s)${NC}"
    echo -e "${YELLOW}⚠ $WARNINGS avertissement(s)${NC}"
    echo ""
    echo "Corrigez les erreurs avant de déployer"
    exit 1
fi
