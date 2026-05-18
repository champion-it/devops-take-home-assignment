output "bucket_name" {
  value       = huaweicloud_obs_bucket.state.bucket
  description = "OBS bucket name."
}

output "bucket_domain_name" {
  value       = huaweicloud_obs_bucket.state.bucket_domain_name
  description = "Fully-qualified bucket endpoint."
}
