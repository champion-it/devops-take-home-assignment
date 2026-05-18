variable "argocd_hostname" {
  type        = string
  description = "Private DNS hostname for the Argo CD UI (e.g. argocd.example.internal)."
}

variable "git_repo" {
  type        = string
  description = "Git repository URL Argo CD will sync from."
}

variable "git_revision" {
  type    = string
  default = "main"
}

variable "git_apps_path" {
  type        = string
  description = "Path inside the repo containing child Application manifests."
  default     = "gitops/application-argocd"
}

variable "ingress_nodeport_http" {
  type    = number
  default = 30080
}

variable "ingress_nodeport_https" {
  type    = number
  default = 30443
}

variable "admin_cidr_allowlist" {
  type        = list(string)
  description = "CIDR blocks allowed to hit admin Ingress paths (Argo CD, Grafana, Vault UI). Default: VPC ranges only."
  default     = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
}
