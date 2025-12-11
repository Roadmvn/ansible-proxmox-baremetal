# Terraform - S3 Infrastructure

Configuration Terraform pour créer et gérer le bucket S3 de backups Proxmox sur un stockage S3-compatible.

## Prérequis

- Terraform >= 1.0
- Credentials S3 (AWS, MinIO, Wasabi, etc.)

## Installation

```bash
# Installer Terraform (si pas déjà installé)
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/
```

## Configuration

1. Copier le fichier de variables :
```bash
cp terraform.tfvars.example terraform.tfvars
```

2. Éditer `terraform.tfvars` avec vos credentials S3

## Utilisation

### Initialiser Terraform
```bash
terraform init
```

### Voir le plan d'exécution
```bash
terraform plan
```

### Créer l'infrastructure
```bash
terraform apply
```

### Afficher les outputs
```bash
terraform output
```

### Détruire l'infrastructure (⚠️ ATTENTION)
```bash
terraform destroy
```

## Structure créée

- **Bucket S3** : `your-bucket-name` (configurable)
- **Chiffrement** : AES256 (côté serveur)
- **Versioning** : Désactivé par défaut
- **Accès public** : Bloqué
- **Lifecycle** :
  - Suppression des uploads incomplets après 7 jours

## Repositories Kopia

Après création du bucket, les repositories Kopia seront :
- `s3://your-bucket-name/node1-repo/`
- `s3://your-bucket-name/node2-repo/`
- `s3://your-bucket-name/node3-repo/`

## Maintenance

### Voir l'état actuel
```bash
terraform show
```

### Formater les fichiers
```bash
terraform fmt
```

### Valider la configuration
```bash
terraform validate
```

## Sécurité

- Ne committez JAMAIS `terraform.tfvars` (contient credentials)
- Le fichier `.gitignore` exclut automatiquement les fichiers sensibles
- Les credentials sont marqués comme `sensitive` dans les variables

## Troubleshooting

### Erreur de provider
Si vous avez une erreur de provider, vérifiez que l'endpoint S3 est correct.

### Erreur d'authentification
Vérifiez vos credentials S3 dans `terraform.tfvars`.

## Documentation

- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [S3 Bucket Resource](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket)
