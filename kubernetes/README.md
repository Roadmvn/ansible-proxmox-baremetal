# Applications Kubernetes

Manifests Kubernetes pour les applications deployees sur le cluster.

## Structure

```
kubernetes/
├── Makefile              # Commandes de deploiement
├── README.md
│
└── apps/
    ├── _template/        # Template pour nouvelles apps
    │   ├── base/
    │   └── overlays/
    │       └── production/
    │
    ├── gophish/          # Outil de phishing simulation
    │   ├── base/
    │   │   ├── kustomization.yml
    │   │   ├── namespace.yml
    │   │   ├── secret.yml
    │   │   ├── mysql.yml
    │   │   └── gophish.yml
    │   └── overlays/
    │       └── production/
    │           ├── kustomization.yml
    │           ├── ingress.yml
    │           └── secrets-patch.yml
    │
    └── plane/            # Gestion de projet
        ├── base/
        └── overlays/
```

## Prerequis

1. Cluster Kubernetes deploye via Kubespray
2. kubeconfig configure

```bash
# Depuis le dossier ansible/
make k8s-kubeconfig K8S_ENV=production
export KUBECONFIG=~/.kube/config-production
```

## Deploiement

```bash
# Verifier la connexion
make check

# Deployer GoPhish
make apps-gophish

# Deployer toutes les apps
make apps-all

# Statut
make status
```

## Ajouter une nouvelle application

1. Copier le template
```bash
cp -r apps/_template apps/mon-app
```

2. Modifier les fichiers dans `base/`
3. Adapter `overlays/production/`
4. Ajouter les commandes dans le Makefile

## Kustomize

Les apps utilisent Kustomize pour gerer les environnements :

```bash
# Voir ce qui sera deploye
kubectl kustomize apps/gophish/overlays/production

# Deployer
kubectl apply -k apps/gophish/overlays/production

# Supprimer
kubectl delete -k apps/gophish/overlays/production
```
