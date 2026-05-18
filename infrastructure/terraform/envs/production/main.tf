terraform {
  required_version = ">= 1.5.0"
  required_providers {
    huaweicloud = {
      source  = "huaweicloud/huaweicloud"
      version = ">= 1.65.0"
    }
    # helm + kubernetes providers are only needed for the argocd_bootstrap
    # module. Re-enable once the bootstrap module is wired (currently commented
    # below pending CCE 1.91 kubeconfig fix).
    # helm = {
    #   source  = "hashicorp/helm"
    #   version = ">= 2.12"
    # }
    # kubernetes = {
    #   source  = "hashicorp/kubernetes"
    #   version = ">= 2.27"
    # }
  }
}

provider "huaweicloud" {
  region = var.region
}

locals {
  env  = "production"
  name = "devops-demo"
  tags = {
    project = "devops-demo"
    env     = local.env
    owner   = "devops-team"
  }

  # ──── Pre-existing resources we REFERENCE but never destroy ──────────────
  # Terraform doesn't manage these — `terraform destroy` will leave them
  # alone because no resource blocks own them, only data sources / IDs.
  existing_vpc_id = "e02a9d40-fdec-4da9-9985-33b39a49b6c1" # vpc-dev (10.26.0.0/16)
  cce_node_sg_id  = "553bf858-57b1-49c6-a089-32cf47331ee2" # sg-dev-cce-node
}

# Fail-fast: exactly one of key_pair_name / root_password must be provided.
check "auth_method" {
  assert {
    condition = (
      (var.key_pair_name != null && var.root_password == null) ||
      (var.key_pair_name == null && var.root_password != null)
    )
    error_message = "Set exactly ONE of key_pair_name or root_password in terraform.tfvars."
  }
}

# --- kubeconfig + helm/kubernetes providers (disabled for first apply) -----
# Re-enable AFTER the initial infra apply succeeds and we know which
# kubeconfig attribute the CCE resource actually exposes in provider 1.91.
# resource "local_file" "kubeconfig" {
#   content         = module.cce.kubeconfig
#   filename        = "${path.module}/.kubeconfig"
#   file_permission = "0600"
# }
# provider "kubernetes" {
#   config_path = local_file.kubeconfig.filename
# }
# provider "helm" {
#   kubernetes = {
#     config_path = local_file.kubeconfig.filename
#   }
# }

# ───────── Reference existing vpc-dev (CIDR 10.26.0.0/16) ─────────────────
# Read-only — Terraform won't touch this on destroy. The shared NAT gateway
# `nat-dev` lives in this VPC too and provides egress for any new subnet
# placed here (default route table).
data "huaweicloud_vpc" "this" {
  id = local.existing_vpc_id
}

# New subnet inside vpc-dev for our CCE workers. Picked 10.26.100.0/24 to
# avoid the existing 3 subnets in vpc-dev — adjust if it collides.
# This subnet IS Terraform-managed, so destroy will remove it.
resource "huaweicloud_vpc_subnet" "worker" {
  name              = "${local.name}-subnet-a"
  vpc_id            = data.huaweicloud_vpc.this.id
  cidr              = "10.26.100.0/24"
  gateway_ip        = "10.26.100.1"
  availability_zone = var.availability_zones[0]
  dhcp_enable       = true
  tags              = local.tags
}

module "swr" {
  source       = "../../modules/swr"
  organization = "devops-demo"
  repositories = ["devops-backend", "devops-frontend"]
}

module "cce" {
  source          = "../../modules/cce"
  cluster_name    = "${local.name}-cce"
  cluster_version = "v1.33"        # Kubernetes 1.33
  cluster_flavor  = "cce.s2.small" # HA 3-master, supports Turbo (eni networking)
  vpc_id          = data.huaweicloud_vpc.this.id
  # CCE Turbo:
  #   subnet_id     = VPC subnet ID (huaweicloud_vpc_subnet.id) for cluster
  #   eni_subnet_id = IPv4 subnet (network) ID for Pod ENIs (same subnet here)
  subnet_id     = huaweicloud_vpc_subnet.worker.id
  eni_subnet_id = huaweicloud_vpc_subnet.worker.ipv4_subnet_id
  tags          = local.tags
}

# ---- Single worker node pool (1 node, AZ-a) -------------------------------
# Minimal pool for dev/demo. Scales 1→3 if load increases.
resource "huaweicloud_cce_node_pool" "this" {
  cluster_id         = module.cce.cluster_id
  name               = "${local.name}-cce-pool"
  os                 = "Huawei Cloud EulerOS 2.0" # HCE OS 2.0
  initial_node_count = 1
  flavor_id          = "c7n.xlarge.2"
  availability_zone  = var.availability_zones[0]
  subnet_id          = huaweicloud_vpc_subnet.worker.id

  # Pre-existing CCE node SG (sg-dev-cce-node). Terraform only references the
  # ID — it doesn't own the SG, so `terraform destroy` will NOT delete it.
  security_groups = [local.cce_node_sg_id]

  key_pair = var.key_pair_name
  password = var.root_password

  scall_enable             = true
  min_node_count           = 1
  max_node_count           = 3
  scale_down_cooldown_time = 300
  priority                 = 1
  type                     = "vm"

  root_volume {
    size       = 50
    volumetype = "SSD"
  }
  data_volumes {
    size       = 100
    volumetype = "SSD"
  }

  tags = local.tags
}

module "elb" {
  source             = "../../modules/elb"
  elb_name           = "${local.name}-elb"
  vpc_id             = data.huaweicloud_vpc.this.id
  ipv4_subnet_id     = huaweicloud_vpc_subnet.worker.ipv4_subnet_id
  availability_zones = var.availability_zones
  create_public_eip  = true
  eip_bandwidth_mbps = 20

  # First apply: leave the pool empty. After CCE is up we'll discover worker
  # IPs via `huaweicloud_compute_instance` data source and add members.
  worker_node_ips        = {}
  ingress_nodeport_http  = 30080
  ingress_nodeport_https = 30443
  enable_https_listener  = false # TLS terminates at ingress-nginx (cert-manager)

  tags = local.tags
}

# ---- Private DNS for admin tools (Argo CD / Grafana / Vault / Prometheus) --
module "private_dns" {
  source    = "../../modules/private-dns"
  zone_name = "example.internal."
  vpc_id    = data.huaweicloud_vpc.this.id
  region    = var.region

  # All admin hostnames point at the public ELB's private IP. Resolves only
  # from inside the VPC, so external attackers can't discover these names.
  records = {
    "argocd"     = module.elb.elb_private_ip
    "grafana"    = module.elb.elb_private_ip
    "vault"      = module.elb.elb_private_ip
    "prometheus" = module.elb.elb_private_ip
  }

  tags = local.tags
}

# ---- Bootstrap Argo CD + ingress-nginx (DISABLED for first apply) ---------
# Depends on the kubeconfig from CCE — re-enable once that's working in 1.91.
# module "argocd_bootstrap" {
#   source = "../../modules/argocd-bootstrap"
#
#   argocd_hostname        = "argocd.example.internal"
#   git_repo               = var.git_repo
#   git_revision           = var.git_revision
#   ingress_nodeport_http  = 30080
#   ingress_nodeport_https = 30443
#   admin_cidr_allowlist   = ["10.20.0.0/16"]
#
#   depends_on = [module.cce, module.elb, module.private_dns]
# }
