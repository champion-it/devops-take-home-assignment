output "zone_id" {
  value       = huaweicloud_dns_zone.internal.id
  description = "Private DNS zone ID."
}

output "zone_name" {
  value       = huaweicloud_dns_zone.internal.name
  description = "Fully-qualified zone name (with trailing dot)."
}

output "fqdns" {
  value       = { for k, v in huaweicloud_dns_recordset.a : k => v.name }
  description = "Map of short name → FQDN for each record created."
}
