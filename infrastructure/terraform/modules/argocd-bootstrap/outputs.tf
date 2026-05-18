output "argocd_namespace" {
  value = kubernetes_namespace.argocd.metadata[0].name
}

output "argocd_url" {
  value       = "https://${var.argocd_hostname}"
  description = "Argo CD UI URL (resolve via private DNS, reach via VPN/Bastion)."
}

output "initial_admin_secret_hint" {
  value       = "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
  description = "Command to print the auto-generated admin password after bootstrap."
}
