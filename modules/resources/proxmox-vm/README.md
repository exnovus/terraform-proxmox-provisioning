# proxmox-vm

Módulo Terraform de workload para aprovisionar VMs en Proxmox con el proveedor `bpg/proxmox`.

Es un bloque interno reutilizable del repositorio. Puede consumirse desde Terraform puro, pero la arquitectura del proyecto requiere que Terragrunt entre por `modules/components/vm-service`, no directamente por este directorio.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_proxmox"></a> [proxmox](#requirement\_proxmox) | ~> 0.98 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_proxmox"></a> [proxmox](#provider\_proxmox) | ~> 0.98 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [proxmox_virtual_environment_file.cloud_init_meta](https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_file) | resource |
| [proxmox_virtual_environment_vm.vm](https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_vm) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_client"></a> [client](#input\_client) | Client code used in resource names | `string` | n/a | yes |
| <a name="input_core_tags"></a> [core\_tags](#input\_core\_tags) | Deprecated: kept for backward compat. Use tags. | `map(string)` | `{}` | no |
| <a name="input_ct_groups"></a> [ct\_groups](#input\_ct\_groups) | Unused in this module; kept to allow unified stack inputs | `map(any)` | `{}` | no |
| <a name="input_custom_tags"></a> [custom\_tags](#input\_custom\_tags) | Deprecated: kept for backward compat. Use tags. | `map(string)` | `{}` | no |
| <a name="input_datacenter"></a> [datacenter](#input\_datacenter) | Datacenter full name | `string` | `""` | no |
| <a name="input_datacenter_short"></a> [datacenter\_short](#input\_datacenter\_short) | Datacenter short code used in resource names | `string` | n/a | yes |
| <a name="input_default_agent_enabled"></a> [default\_agent\_enabled](#input\_default\_agent\_enabled) | Enable QEMU Guest Agent by default. Requires qemu-guest-agent installed in the guest. | `bool` | `true` | no |
| <a name="input_default_agent_timeout"></a> [default\_agent\_timeout](#input\_default\_agent\_timeout) | Guest agent timeout (for example 5m or 120). Applies only when agent\_enabled = true, wait\_for\_agent = true, and the VM is created from a template. | `string` | `"5m"` | no |
| <a name="input_default_bridge"></a> [default\_bridge](#input\_default\_bridge) | Default network bridge | `string` | `"vmbr0"` | no |
| <a name="input_default_cloud_init_set_hostname"></a> [default\_cloud\_init\_set\_hostname](#input\_default\_cloud\_init\_set\_hostname) | Publish local-hostname via cloud-init metadata for cloned VMs when the group does not override it. | `bool` | `false` | no |
| <a name="input_default_cloud_init_snippets_storage"></a> [default\_cloud\_init\_snippets\_storage](#input\_default\_cloud\_init\_snippets\_storage) | Proxmox storage with snippets support used for custom cloud-init metadata. | `string` | `"local"` | no |
| <a name="input_default_cpu_type"></a> [default\_cpu\_type](#input\_default\_cpu\_type) | Default CPU type. Use 'host' for best performance, 'x86-64-v2-AES' for broad compat. | `string` | `"host"` | no |
| <a name="input_default_disk_discard"></a> [default\_disk\_discard](#input\_default\_disk\_discard) | Discard mode for disks (on=TRIM, unmap, ignore). | `string` | `"on"` | no |
| <a name="input_default_disk_iothread"></a> [default\_disk\_iothread](#input\_default\_disk\_iothread) | Enable IO thread per disk. Only effective when scsihw = virtio-scsi-single. | `bool` | `true` | no |
| <a name="input_default_disk_ssd"></a> [default\_disk\_ssd](#input\_default\_disk\_ssd) | Emulate the disk as SSD. | `bool` | `true` | no |
| <a name="input_default_machine"></a> [default\_machine](#input\_default\_machine) | QEMU machine type. Use 'q35' for modern guests with PCIe passthrough support. | `string` | `"q35"` | no |
| <a name="input_default_node"></a> [default\_node](#input\_default\_node) | Fallback node when no target\_nodes are provided | `string` | `null` | no |
| <a name="input_default_os_template"></a> [default\_os\_template](#input\_default\_os\_template) | Unused in VM module; accepted for shared stack contract | `string` | `null` | no |
| <a name="input_default_pool"></a> [default\_pool](#input\_default\_pool) | Default Proxmox pool | `string` | `null` | no |
| <a name="input_default_scsihw"></a> [default\_scsihw](#input\_default\_scsihw) | SCSI controller type. Use 'virtio-scsi-single' to enable per-disk iothread. | `string` | `"virtio-scsi-single"` | no |
| <a name="input_default_sockets"></a> [default\_sockets](#input\_default\_sockets) | Default CPU socket count | `number` | `1` | no |
| <a name="input_default_ssh_pubkey_path"></a> [default\_ssh\_pubkey\_path](#input\_default\_ssh\_pubkey\_path) | Path to the SSH public key file for cloud-init (optional). | `string` | `null` | no |
| <a name="input_default_start_on_create"></a> [default\_start\_on\_create](#input\_default\_start\_on\_create) | Start the VM immediately after Terraform creates it (maps to provider attribute 'started'). Only applies when use\_clone = true; without a template, started remains false. | `bool` | `true` | no |
| <a name="input_default_storage"></a> [default\_storage](#input\_default\_storage) | Default storage backend for VM disks | `string` | `"local-lvm"` | no |
| <a name="input_default_target_nodes"></a> [default\_target\_nodes](#input\_default\_target\_nodes) | Default target node rotation list | `list(string)` | `[]` | no |
| <a name="input_default_template"></a> [default\_template](#input\_default\_template) | Default cloud-init VM template name. Informational only; clone mode uses default\_template\_vm\_id. | `string` | `null` | no |
| <a name="input_default_template_vm_id"></a> [default\_template\_vm\_id](#input\_default\_template\_vm\_id) | Template VMID in Proxmox for clone mode. Required when use\_clone = true. | `number` | `null` | no |
| <a name="input_default_vm_id_base"></a> [default\_vm\_id\_base](#input\_default\_vm\_id\_base) | Base VMID used to derive unique VM IDs (vm\_id = base + ordinal). Avoid collisions across stacks. | `number` | `4000` | no |
| <a name="input_default_wait_for_agent"></a> [default\_wait\_for\_agent](#input\_default\_wait\_for\_agent) | Wait for the QEMU Guest Agent to publish interfaces when the agent is enabled and the VM is created from a template. Without a template, this avoids the 15-minute timeout. | `bool` | `true` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment code used in resource names | `string` | n/a | yes |
| <a name="input_naming_delimiter"></a> [naming\_delimiter](#input\_naming\_delimiter) | Delimiter used in naming | `string` | `"-"` | no |
| <a name="input_owner"></a> [owner](#input\_owner) | Owner for this stack | `string` | `""` | no |
| <a name="input_role"></a> [role](#input\_role) | Default stack role | `string` | `""` | no |
| <a name="input_stack_name"></a> [stack\_name](#input\_stack\_name) | Stack name | `string` | `""` | no |
| <a name="input_stack_version"></a> [stack\_version](#input\_stack\_version) | Stack version | `string` | `"1.0.0"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Pre-sanitized base tags map. Passed by the stack wrapper from terraform-tags.tags\_sanitized. | `map(string)` | `{}` | no |
| <a name="input_vm_groups"></a> [vm\_groups](#input\_vm\_groups) | Map of VM groups to expand into individual VMs | <pre>map(object({<br/>    enabled        = optional(bool, true)<br/>    role           = string<br/>    count          = number<br/>    cpu            = number<br/>    ram_mb         = number<br/>    disk_gb        = number<br/>    template       = optional(string)<br/>    template_vm_id = optional(number)<br/>    use_clone      = optional(bool, false)<br/>    target_nodes   = optional(list(string), [])<br/>    node           = optional(string)<br/>    bridge         = optional(string)<br/>    storage        = optional(string)<br/>    pool           = optional(string)<br/><br/>    machine                 = optional(string)<br/>    sockets                 = optional(number)<br/>    cpu_type                = optional(string)<br/>    agent_enabled           = optional(bool)<br/>    scsihw                  = optional(string)<br/>    disk_iothread           = optional(bool)<br/>    start_on_create         = optional(bool)<br/>    wait_for_agent          = optional(bool)<br/>    agent_timeout           = optional(string)<br/>    cloud_init_set_hostname = optional(bool)<br/>    ssh_pubkey_path         = optional(string)<br/><br/>    tags        = optional(map(string), {})<br/>    custom_tags = optional(map(string), {})<br/>    extra_disks = optional(list(object({<br/>      interface    = string<br/>      datastore_id = optional(string)<br/>      size_gb      = number<br/>      iothread     = optional(bool)<br/>      discard      = optional(string)<br/>      ssd          = optional(bool)<br/>    })), [])<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_vm_instances"></a> [vm\_instances](#output\_vm\_instances) | Expanded VM instance map used to provision VMs |
| <a name="output_vm_names"></a> [vm\_names](#output\_vm\_names) | Provisioned VM names |
<!-- END_TF_DOCS -->
