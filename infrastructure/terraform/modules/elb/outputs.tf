output "elb_id" {
  value       = huaweicloud_elb_loadbalancer.this.id
  description = "ELB ID — pass this into the K8s Ingress annotation `kubernetes.io/elb.id`."
}

output "elb_private_ip" {
  value       = huaweicloud_elb_loadbalancer.this.ipv4_address
  description = "Private VIP of the ELB."
}

output "elb_public_ip" {
  value       = length(huaweicloud_vpc_eip.this) > 0 ? huaweicloud_vpc_eip.this[0].address : null
  description = "Public EIP attached to the ELB (null if create_public_eip = false)."
}
