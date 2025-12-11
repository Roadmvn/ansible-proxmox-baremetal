# Template Application

Template pour creer une nouvelle application Kubernetes.

## Utilisation

```bash
# 1. Copier le template
cp -r _template mon-app

# 2. Remplacer APP_NAME partout
cd mon-app
find . -type f -exec sed -i 's/APP_NAME/mon-app/g' {} \;

# 3. Modifier les fichiers selon vos besoins
#    - base/deployment.yml : image, ports, env
#    - overlays/production/ingress.yml : domaine

# 4. Ajouter au Makefile principal
#    apps-mon-app: kubectl apply -k apps/mon-app/overlays/production
```

## Structure

```
mon-app/
├── base/
│   ├── kustomization.yml
│   ├── namespace.yml
│   ├── deployment.yml
│   └── service.yml
└── overlays/
    └── production/
        ├── kustomization.yml
        └── ingress.yml
```
