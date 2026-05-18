# Terraform — Huawei Cloud Infrastructure

Modular, environment-separated Terraform for the DevOps take-home project.

## Structure

```
infra/terraform/
├── bootstrap/             # ONE-TIME: provisions the OBS bucket used as remote backend.
├── modules/
│   ├── vpc/               # VPC + subnets + (optional) NAT gateway
│   ├── cce/               # Cloud Container Engine (managed Kubernetes) + node pool
│   ├── swr/               # Software Repository for Container (image registry)
│   ├── elb/               # Elastic Load Balance (dedicated) + optional EIP
│   └── obs-backend/       # OBS bucket for Terraform remote state
└── envs/
    ├── staging/           # 2x s6.xlarge.2 worker nodes
    └── production/        # 3x s6.xlarge.2 worker nodes, larger ELB bandwidth
```

## Prerequisites

1. **Huawei Cloud account** with an active project in your chosen region (default `ap-southeast-2`, Bangkok — 3 AZs available).
2. **Access keys (AK/SK)** exported as environment variables — the S3-compatible
   backend reads them through the AWS env names:

   ```powershell
   $env:HW_ACCESS_KEY        = "<your AK>"   # used by the Huawei provider
   $env:HW_SECRET_KEY        = "<your SK>"
   $env:AWS_ACCESS_KEY_ID    = "<your AK>"   # used by the S3 backend
   $env:AWS_SECRET_ACCESS_KEY = "<your SK>"
   ```

3. **An existing SSH key pair** in your Huawei Cloud project (`ECS → Key Pairs`),
   passed as `key_pair_name`.

4. **Terraform ≥ 1.5** and **kubectl ≥ 1.29** installed locally.

## One-time bootstrap

```powershell
cd infra/terraform/bootstrap
terraform init
terraform apply -var="state_bucket_name=devops-takehome-tfstate"
```

This creates the OBS bucket `devops-takehome-tfstate` with versioning + AES256
encryption enabled. The bootstrap stack itself keeps its state local (commit it
to a private location or migrate it into the same bucket after the fact).

## Provision an environment

```powershell
cd infra/terraform/envs/staging
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars to set your key_pair_name

terraform init
terraform plan -out staging.plan
terraform apply staging.plan
```

After apply, export the kubeconfig for use with `kubectl`/`helm`:

```powershell
terraform output -raw kubeconfig | Out-File -FilePath $HOME/.kube/config-staging -Encoding utf8
$env:KUBECONFIG = "$HOME/.kube/config-staging"
kubectl get nodes
```

## What you get

| Resource | Staging | Production |
|----------|---------|------------|
| VPC CIDR | 10.10.0.0/16 | 10.20.0.0/16 |
| CCE flavor | `cce.s1.small` | `cce.s2.medium` |
| Worker nodes | 2× `s6.xlarge.2` (4vCPU / 8GiB) | 3× `s6.xlarge.2` (4vCPU / 8GiB) |
| Autoscaling | 2 → 4 | 3 → 8 |
| ELB bandwidth | 5 Mbps | 20 Mbps |
| Public EIP | yes | yes |
| NAT gateway | yes | yes |

## Cleanup

```powershell
cd infra/terraform/envs/staging
terraform destroy
```

The OBS bucket has `force_destroy = false` — empty it manually or set the flag
to `true` and re-apply before destroying the bootstrap stack.
