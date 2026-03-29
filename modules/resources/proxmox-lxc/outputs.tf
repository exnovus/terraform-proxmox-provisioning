output "ct_instances" {
  description = "Expanded CT instance map used to provision CTs"
  value       = local.enabled_ct_instances
}

output "ct_names" {
  description = "Provisioned CT hostnames"
  value       = [for ct in values(local.enabled_ct_instances) : ct.ct_name]
}
