output "vpc_id" {
  value       = data.huaweicloud_vpc.this.id
  description = "ID of the existing vpc-dev (referenced, not managed)."
}

output "subnet_id" {
  value       = huaweicloud_vpc_subnet.worker.id
  description = "Worker subnet ID (created by Terraform inside vpc-dev)."
}

output "cluster_id" {
  value = module.cce.cluster_id
}

output "swr_login_server" {
  value = module.swr.login_server
}

output "image_urls" {
  value = module.swr.repository_urls
}

output "elb_id" {
  value = module.elb.elb_id
}

output "elb_public_ip" {
  value = module.elb.elb_public_ip
}

output "kubeconfig" {
  value     = module.cce.kubeconfig
  sensitive = true
}
