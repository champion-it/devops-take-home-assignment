output "cluster_id" {
  value       = huaweicloud_cce_cluster.this.id
  description = "CCE cluster ID."
}

output "cluster_name" {
  value       = huaweicloud_cce_cluster.this.name
  description = "CCE cluster name."
}

# Provider 1.91+ exposes kubeconfig directly on the cluster resource.
output "kubeconfig" {
  value       = try(huaweicloud_cce_cluster.this.kube_config_raw, "")
  description = "Raw kubeconfig YAML for the cluster (empty if attribute unavailable)."
  sensitive   = true
}
