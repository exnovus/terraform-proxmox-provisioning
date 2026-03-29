output "vm_instances" {
  description = "Expanded VM instance map used to provision VMs"
  value       = local.all_vm_instances
}

output "vm_names" {
  description = "Provisioned VM names"
  value       = [for vm in values(proxmox_virtual_environment_vm.vm) : vm.name]
}
