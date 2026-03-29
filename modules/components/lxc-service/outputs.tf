output "ct_instances" {
  description = "Expanded CT instance map used to provision containers"
  value       = module.workload.ct_instances
}

output "ct_names" {
  description = "Provisioned CT hostnames"
  value       = module.workload.ct_names
}

output "tags_id" {
  description = "Normalized stack id from terraform-tags"
  value       = module.terraform_tags.id
}

output "tags_sanitized" {
  description = "Sanitized base tags map"
  value       = module.terraform_tags.tags_sanitized
}

output "taglist_base" {
  description = "Base taglist string (before resource-level tags)"
  value       = module.terraform_tags.taglist
}
