# ArgoCD bootstrap for `kustomize-demo`

Per-service `Application` manifests pointing to
`http://gitlab.dwl.internal/infrastructure/gitops/kustomize-demo.git`.

## Files

| File | Purpose |
|---|---|
| `repo-secret.yaml`       | GitLab repo credentials (HTTPS + token) |
| `project.yaml`           | `AppProject devops-demo` scoping allowed repos/destinations |
| `app-dev-shared.yaml`    | NetworkPolicies, etc. — auto-sync |
| `app-dev-backend.yaml`   | Backend (blue/green, HPA, Service, HTTPRoute, VaultStaticSecret) — auto-sync |
| `app-dev-frontend.yaml`  | Frontend — auto-sync |
| `app-prod-shared.yaml`   | Same as dev shared but **manual sync** |
| `app-prod-backend.yaml`  | Same as dev backend but **manual sync** |
| `app-prod-frontend.yaml` | Same as dev frontend but **manual sync** |

## Sync policy

- **dev**: `automated.prune + selfHeal` — any drift is reverted, deleted resources cleaned up.
- **prod**: manual sync only — trigger via UI or `argocd app sync devops-demo-prod-<svc>`.
- **HPA-controlled replicas** are excluded from drift detection via `ignoreDifferences`
  (Deployment `/spec/replicas`) — prevents ArgoCD from fighting the autoscaler.

## Apply order

```bash
# Repo creds + project must exist before Applications.
kubectl apply -f repo-secret.yaml
kubectl apply -f project.yaml

# Shared first (namespace, NetworkPolicies), then services.
kubectl apply -f app-dev-shared.yaml
kubectl apply -f app-dev-backend.yaml
kubectl apply -f app-dev-frontend.yaml

# prod (optional, manual sync)
kubectl apply -f app-prod-shared.yaml
kubectl apply -f app-prod-backend.yaml
kubectl apply -f app-prod-frontend.yaml
```

## Migrate from old monolithic Application (if applied earlier)

If you previously applied a single `devops-demo-dev` Application, drop the
finalizer first so existing resources are NOT deleted, then remove the App:

```bash
kubectl patch application devops-demo-dev -n argocd \
  -p '{"metadata":{"finalizers":null}}' --type=merge
kubectl delete application devops-demo-dev -n argocd

# Same for prod if it was applied
kubectl patch application devops-demo-prod -n argocd \
  -p '{"metadata":{"finalizers":null}}' --type=merge
kubectl delete application devops-demo-prod -n argocd
```

The new per-service Applications will adopt the existing resources on next sync.

## Verify

```bash
argocd app list
kubectl get application -n argocd
kubectl get pods,svc,httproute -n devops-demo
```
