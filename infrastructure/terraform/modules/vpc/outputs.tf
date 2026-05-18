output "vpc_id" {
  value       = huaweicloud_vpc.this.id
  description = "ID of the created VPC."
}

output "vpc_cidr" {
  value       = huaweicloud_vpc.this.cidr
  description = "CIDR of the VPC."
}

output "subnet_ids" {
  value       = { for k, v in huaweicloud_vpc_subnet.this : k => v.id }
  description = "Map of subnet name -> subnet ID."
}

output "subnet_ipv4_ids" {
  value       = { for k, v in huaweicloud_vpc_subnet.this : k => v.ipv4_subnet_id }
  description = "Map of subnet name -> IPv4 subnet (network) ID, required by CCE/ELB."
}
