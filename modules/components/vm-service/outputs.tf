output "vm_instances" {
  description = "Expanded VM instance map used to provision VMs"
  value       = module.workload.vm_instances
}

output "vm_names" {
  description = "Provisioned VM names"
  value       = module.workload.vm_names
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
