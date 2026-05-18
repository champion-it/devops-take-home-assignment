output "organization" {
  value       = huaweicloud_swr_organization.this.name
  description = "SWR organization name."
}

output "login_server" {
  value       = huaweicloud_swr_organization.this.login_server
  description = "SWR login server hostname (e.g. swr.ap-southeast-2.myhuaweicloud.com)."
}

output "repository_urls" {
  value = {
    for k, v in huaweicloud_swr_repository.repos :
    k => "${huaweicloud_swr_organization.this.login_server}/${huaweicloud_swr_organization.this.name}/${v.name}"
  }
  description = "Map of repo name -> fully-qualified image path."
}
