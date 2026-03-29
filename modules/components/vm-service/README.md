# vm-service

Punto de entrada de componente para stacks de VM. Orquesta `tags-manager` y `resources/proxmox-vm` bajo el contrato compartido del repositorio.

Este es el módulo que debe invocar Terragrunt para cargas de trabajo VM. No redirijas Terragrunt al módulo de `resources`.

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_terraform_tags"></a> [terraform\_tags](#module\_terraform\_tags) | ../../core/tags-manager | n/a |
| <a name="module_workload"></a> [workload](#module\_workload) | ../../resources/proxmox-vm | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_client"></a> [client](#input\_client) | Client code used in resource names | `string` | n/a | yes |
| <a name="input_core_tags"></a> [core\_tags](#input\_core\_tags) | Deprecated: accepted for compat, not used. Tags are merged in Terragrunt. | `map(string)` | `{}` | no |
| <a name="input_ct_groups"></a> [ct\_groups](#input\_ct\_groups) | Unused in VM stack; accepted for shared contract | `map(any)` | `{}` | no |
| <a name="input_custom_tags"></a> [custom\_tags](#input\_custom\_tags) | Deprecated: accepted for compat, not used. Tags are merged in Terragrunt. | `map(string)` | `{}` | no |
| <a name="input_datacenter"></a> [datacenter](#input\_datacenter) | Datacenter full name | `string` | `""` | no |
| <a name="input_datacenter_short"></a> [datacenter\_short](#input\_datacenter\_short) | Datacenter short code used in resource names | `string` | n/a | yes |
| <a name="input_default_bridge"></a> [default\_bridge](#input\_default\_bridge) | Default network bridge | `string` | `"vmbr0"` | no |
| <a name="input_default_cloud_init_set_hostname"></a> [default\_cloud\_init\_set\_hostname](#input\_default\_cloud\_init\_set\_hostname) | Publish local-hostname via cloud-init metadata for cloned VMs when the group does not override it. | `bool` | `false` | no |
| <a name="input_default_cloud_init_snippets_storage"></a> [default\_cloud\_init\_snippets\_storage](#input\_default\_cloud\_init\_snippets\_storage) | Proxmox storage with snippets support used for custom cloud-init metadata. | `string` | `"local"` | no |
| <a name="input_default_node"></a> [default\_node](#input\_default\_node) | Fallback node when no target\_nodes are provided | `string` | `null` | no |
| <a name="input_default_os_template"></a> [default\_os\_template](#input\_default\_os\_template) | Unused in VM stack; accepted for shared contract | `string` | `null` | no |
| <a name="input_default_pool"></a> [default\_pool](#input\_default\_pool) | Default Proxmox pool | `string` | `null` | no |
| <a name="input_default_storage"></a> [default\_storage](#input\_default\_storage) | Default storage backend | `string` | `"local-lvm"` | no |
| <a name="input_default_target_nodes"></a> [default\_target\_nodes](#input\_default\_target\_nodes) | Default target node rotation list | `list(string)` | `[]` | no |
| <a name="input_default_template"></a> [default\_template](#input\_default\_template) | Default cloud-init VM template | `string` | `null` | no |
| <a name="input_default_template_vm_id"></a> [default\_template\_vm\_id](#input\_default\_template\_vm\_id) | Default template VMID used when VM groups enable clone mode | `number` | `null` | no |
| <a name="input_default_vm_id_base"></a> [default\_vm\_id\_base](#input\_default\_vm\_id\_base) | Base VMID used to derive unique VM IDs (vm\_id = base + ordinal). Avoid collisions across stacks. | `number` | `4000` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment code used in resource names | `string` | n/a | yes |
| <a name="input_naming_delimiter"></a> [naming\_delimiter](#input\_naming\_delimiter) | Delimiter used in naming | `string` | `"-"` | no |
| <a name="input_owner"></a> [owner](#input\_owner) | Owner for this stack | `string` | `""` | no |
| <a name="input_role"></a> [role](#input\_role) | Default stack role | `string` | `""` | no |
| <a name="input_stack_name"></a> [stack\_name](#input\_stack\_name) | Stack name | `string` | `""` | no |
| <a name="input_stack_version"></a> [stack\_version](#input\_stack\_version) | Stack version | `string` | `"1.0.0"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Raw tags from Terragrunt (final\_tags). Sanitized by terraform-tags before passing to workload. | `map(string)` | `{}` | no |
| <a name="input_vm_groups"></a> [vm\_groups](#input\_vm\_groups) | Map of VM groups to expand into individual VMs | <pre>map(object({<br/>    enabled                 = optional(bool, true)<br/>    role                    = string<br/>    count                   = number<br/>    cpu                     = number<br/>    ram_mb                  = number<br/>    disk_gb                 = number<br/>    template                = optional(string)<br/>    template_vm_id          = optional(number)<br/>    use_clone               = optional(bool, false)<br/>    target_nodes            = optional(list(string), [])<br/>    node                    = optional(string)<br/>    bridge                  = optional(string)<br/>    storage                 = optional(string)<br/>    pool                    = optional(string)<br/>    agent_enabled           = optional(bool)<br/>    wait_for_agent          = optional(bool)<br/>    agent_timeout           = optional(string)<br/>    cloud_init_set_hostname = optional(bool)<br/>    tags                    = optional(map(string), {})<br/>    custom_tags             = optional(map(string), {})<br/>    extra_disks = optional(list(object({<br/>      interface    = string<br/>      datastore_id = optional(string)<br/>      size_gb      = number<br/>      iothread     = optional(bool)<br/>      discard      = optional(string)<br/>      ssd          = optional(bool)<br/>    })), [])<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_taglist_base"></a> [taglist\_base](#output\_taglist\_base) | Base taglist string (before resource-level tags) |
| <a name="output_tags_id"></a> [tags\_id](#output\_tags\_id) | Normalized stack id from terraform-tags |
| <a name="output_tags_sanitized"></a> [tags\_sanitized](#output\_tags\_sanitized) | Sanitized base tags map |
| <a name="output_vm_instances"></a> [vm\_instances](#output\_vm\_instances) | Expanded VM instance map used to provision VMs |
| <a name="output_vm_names"></a> [vm\_names](#output\_vm\_names) | Provisioned VM names |
<!-- END_TF_DOCS -->
