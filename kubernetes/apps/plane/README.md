# Plane - Gestion de projet

Plane est un outil open-source de gestion de projet (alternative a Jira).

## Deploiement

Plane utilise Helm (pas Kustomize) :

```bash
# 1. Ajouter le repo Helm
helm repo add makeplane https://helm.plane.so
helm repo update

# 2. Creer le namespace
kubectl apply -f base/namespace.yml

# 3. Deployer avec les values de production
helm install plane makeplane/plane-ce \
  -n plane \
  -f overlays/production/values.yml \
  --timeout 10m \
  --wait

# 4. Verifier
kubectl get pods -n plane
```

## Configuration

Editer `overlays/production/values.yml` :
- `ingress.appHost` : votre domaine
- `storageClass` : classe de stockage disponible

## Mise a jour

```bash
helm upgrade plane makeplane/plane-ce \
  -n plane \
  -f overlays/production/values.yml
```

## Suppression

```bash
helm uninstall plane -n plane
kubectl delete ns plane
```
