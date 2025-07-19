# 📋 Structure Documentaire - Guide de Référence

Ce fichier référence la structure documentaire du projet pour éviter les doublons et maintenir la cohérence.

## 🗂️ Hiérarchie des Documents

### **Niveau 1 : Point d'Entrée Principal**
- **`/README.md`** - Landing page du projet avec démarrage ultra-rapide

### **Niveau 2 : Documentation Technique**
- **`/docs/README.md`** - Hub central de la documentation technique
- **`/docs/ssh_connection_guide.md`** - Guide complet connexion SSH (LE guide SSH de référence)
- **`/docs/deployment_architecture.md`** - Architecture et diagrammes des VMs

### **Niveau 3 : Guides Spécialisés**
- **`/docs/network_configuration.md`** - Configuration ponts réseau vmbr0/vmbr1
- **`/docs/post_creation_guide.md`** - Étapes post-création des VMs
- **`/docs/vm_creation_guide.md`** - Processus détaillé création VM unique

### **Niveau 4 : Guides Avancés**
- **`/docs/rescue_mode_hetzner.md`** - Installation Proxmox from scratch
- **`/docs/vm_runner_deployment.md`** - Déploiement avec GitHub Actions

### **Niveau 5 : Exemples Pratiques**
- **`/examples/README.md`** - Guide des configurations VM
- **`/examples/vm-*.yml`** - Fichiers de configuration spécifiques

---

## 🚫 Fichiers Supprimés (Doublons Identifiés)

| Fichier Supprimé | Raison | Remplacé par |
|------------------|---------|--------------|
| `/ssh_connection_guide.md` | Fichier corrompu à la racine | `/docs/ssh_connection_guide.md` |
| `/docs/architecture_reseau_proxmox.md` | Doublon (372 lignes) | `/docs/deployment_architecture.md` |

---

## 📐 Règles d'Organisation

### **1. Un Seul Fichier par Sujet**
- SSH → `docs/ssh_connection_guide.md` UNIQUEMENT
- Architecture → `docs/deployment_architecture.md` UNIQUEMENT
- Réseau → `docs/network_configuration.md` UNIQUEMENT

### **2. Éviter les Répétitions**
- Chaque information n'existe qu'à UN seul endroit
- Les autres fichiers RÉFÉRENCENT via des liens relatifs
- Pas de copie-coller entre fichiers

### **3. Navigation Clara**
- `README.md` → Démarrage rapide + liens vers docs/
- `docs/README.md` → Hub central technique
- Chaque doc spécialisé → Focus sur son domaine uniquement

### **4. Références Croisées**
```markdown
# ✅ BIEN - Référencer au lieu de répéter
Voir [Guide SSH](./ssh_connection_guide.md) pour les détails

# ❌ MAL - Répéter l'information
## Comment se connecter en SSH
1. ssh root@...
2. ssh imane@...
```

---

## 🎯 Responsabilités par Fichier

| Fichier | Objectif | Contenu Principal |
|---------|----------|-------------------|
| `/README.md` | **Première impression** | Démarrage rapide, aperçu architecture |
| `/docs/README.md` | **Navigation docs** | Index organisé, liens vers guides |
| `/docs/ssh_connection_guide.md` | **Maître SSH** | Toutes les méthodes SSH, troubleshooting |
| `/docs/deployment_architecture.md` | **Maître Architecture** | Diagrammes, IPs, topologie réseau |
| `/docs/network_configuration.md` | **Maître Réseau** | vmbr0/vmbr1, configuration technique |

---

## 🔄 Workflow de Mise à Jour

**Avant d'ajouter du contenu :**
1. ✅ Vérifier si l'info existe déjà dans un autre fichier
2. ✅ Si oui → Ajouter un lien de référence
3. ✅ Si non → L'ajouter dans le fichier le plus logique
4. ✅ Mettre à jour les références croisées

**Cette structure garantit :**
- ✅ Pas de doublons
- ✅ Information centralisée 
- ✅ Navigation intuitive
- ✅ Maintenance simplifiée 