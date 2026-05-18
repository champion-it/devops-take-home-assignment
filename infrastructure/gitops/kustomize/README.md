# Kubernetes Manifests — Blue-Green on CCE

## Layout

```
k8s/
├── base/                      # Shared manifests applied to every env
│   ├── namespace.yaml
│   ├── serviceaccount.yaml    # `backend` SA — bound to a Vault role
│   ├── configmap.yaml         # Non-sensitive config
│   ├── backend-blue.yaml      # "Blue" Deployment of backend (Vault-annotated)
│   ├── backend-green.yaml     # "Green" Deployment of backend
│   ├── backend-service.yaml   # `backend` (live) + `backend-preview`
│   ├── frontend-deployment.yaml
│   ├── hpa.yaml               # Horizontal Pod Autoscalers
│   ├── pdb.yaml               # PodDisruptionBudgets
│   ├── ingress.yaml           # Huawei CCE Ingress wired to the ELB
│   ├── networkpolicy.yaml     # Default-deny + targeted allows
│   └── kustomization.yaml
└── overlays/
    ├── staging/
    └── production/
```

## Deploying

```powershell
# Set the ELB ID from terraform output into the Ingress.
$elbId = terraform -chdir=../infra/terraform/envs/staging output -raw elb_id
(Get-Content k8s/base/ingress.yaml) -replace 'REPLACE_WITH_ELB_ID', $elbId |
  Set-Content k8s/base/ingress.yaml

# Apply
kubectl apply -k k8s/overlays/staging
```

## Blue-Green flow

1. **Initial state:** the `backend` Service selects `color=blue`. `backend-blue`
   serves all traffic; `backend-green` is scaled to 0 (or unused).

2. **Deploy a new version as green:**
   ```powershell
   kubectl -n devops-app set image deployment/backend-green `
     backend=swr.ap-southeast-2.myhuaweicloud.com/devops-takehome/devops-backend:$NEW_SHA
   kubectl -n devops-app scale deployment/backend-green --replicas=3
   kubectl -n devops-app rollout status deployment/backend-green
   ```

3. **Smoke-test the green Pods** via the `backend-preview` Service (port-forward
   or from another Pod in the cluster — `curl backend-preview.devops-app:8080/api/info`).

4. **Flip live traffic:**
   ```powershell
   ./scripts/bluegreen-switch.ps1 -Color green
   ```

5. **Watch metrics for ~5 minutes**, then scale down blue:
   ```powershell
   kubectl -n devops-app scale deployment/backend-blue --replicas=0
   ```

6. **Rollback** is just `bluegreen-switch.ps1 -Color blue` — instantaneous,
   no rebuild needed because blue is still around at 0 replicas.

## Security defaults

- Pods run as non-root with `readOnlyRootFilesystem`, dropping ALL capabilities.
- A default-deny NetworkPolicy is applied; only frontend→backend, ingress→frontend,
  backend→Vault (8200/TCP), monitoring→backend, and DNS are allowed by name.
- **No K8s `Secret` resources** — sensitive values live in HashiCorp Vault and
  are written to a tmpfs at `/vault/secrets/config.env` by the Vault Agent
  Injector at Pod startup. The backend reads the file before booting Express.
  See [vault/README.md](vault/README.md).
