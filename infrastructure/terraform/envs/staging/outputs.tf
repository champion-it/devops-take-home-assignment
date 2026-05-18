output "vpc_id" {
  value = module.vpc.vpc_id
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
  value       = module.elb.elb_id
  description = "Pass to K8s Ingress annotation kubernetes.io/elb.id"
}

output "elb_public_ip" {
  value = module.elb.elb_public_ip
}

output "kubeconfig" {
  value     = module.cce.kubeconfig
  sensitive = true
}
