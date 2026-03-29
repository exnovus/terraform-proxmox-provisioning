# proxmox-lxc

Módulo Terraform de workload para aprovisionar contenedores LXC en Proxmox con el proveedor `bpg/proxmox`.

Es un bloque interno reutilizable del repositorio. Puede consumirse desde Terraform puro, pero la arquitectura del proyecto requiere que Terragrunt entre por `modules/components/lxc-service`, no directamente por este directorio.

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
| [proxmox_virtual_environment_container.ct](https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_container) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_client"></a> [client](#input\_client) | Client code used in resource names | `string` | n/a | yes |
| <a name="input_core_tags"></a> [core\_tags](#input\_core\_tags) | Deprecated: kept for backward compat. Use tags. | `map(string)` | `{}` | no |
| <a name="input_ct_groups"></a> [ct\_groups](#input\_ct\_groups) | Map of CT groups to expand into individual containers | <pre>map(object({<br/>    enabled      = optional(bool, true)<br/>    role         = string<br/>    count        = number<br/>    cpu          = number<br/>    ram_mb       = number<br/>    disk_gb      = number<br/>    os_template  = optional(string)<br/>    target_nodes = optional(list(string), [])<br/>    node         = optional(string)<br/>    bridge       = optional(string)<br/>    storage      = optional(string)<br/>    pool         = optional(string)<br/>    unprivileged = optional(bool, true)<br/>    onboot       = optional(bool, true)<br/>    start        = optional(bool, true)<br/>    ipv4         = optional(string, "dhcp")<br/>    ipv4_gateway = optional(string)<br/>    tags         = optional(map(string), {})<br/>    custom_tags  = optional(map(string), {})<br/>  }))</pre> | `{}` | no |
| <a name="input_custom_tags"></a> [custom\_tags](#input\_custom\_tags) | Deprecated: kept for backward compat. Use tags. | `map(string)` | `{}` | no |
| <a name="input_datacenter"></a> [datacenter](#input\_datacenter) | Datacenter full name | `string` | `""` | no |
| <a name="input_datacenter_short"></a> [datacenter\_short](#input\_datacenter\_short) | Datacenter short code used in resource names | `string` | n/a | yes |
| <a name="input_default_bridge"></a> [default\_bridge](#input\_default\_bridge) | Default network bridge | `string` | `"vmbr0"` | no |
| <a name="input_default_ct_id_base"></a> [default\_ct\_id\_base](#input\_default\_ct\_id\_base) | Base CT ID used to derive unique container IDs | `number` | `200` | no |
| <a name="input_default_node"></a> [default\_node](#input\_default\_node) | Fallback node when no target\_nodes are provided | `string` | `null` | no |
| <a name="input_default_os_template"></a> [default\_os\_template](#input\_default\_os\_template) | Default LXC OS template | `string` | `null` | no |
| <a name="input_default_pool"></a> [default\_pool](#input\_default\_pool) | Default Proxmox pool | `string` | `null` | no |
| <a name="input_default_storage"></a> [default\_storage](#input\_default\_storage) | Default storage backend | `string` | `"local-lvm"` | no |
| <a name="input_default_target_nodes"></a> [default\_target\_nodes](#input\_default\_target\_nodes) | Default target node rotation list | `list(string)` | `[]` | no |
| <a name="input_default_template"></a> [default\_template](#input\_default\_template) | Unused in CT module; accepted for shared stack contract | `string` | `null` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment code used in resource names | `string` | n/a | yes |
| <a name="input_naming_delimiter"></a> [naming\_delimiter](#input\_naming\_delimiter) | Delimiter used in naming | `string` | `"-"` | no |
| <a name="input_owner"></a> [owner](#input\_owner) | Owner for this stack | `string` | `""` | no |
| <a name="input_role"></a> [role](#input\_role) | Default stack role | `string` | `""` | no |
| <a name="input_stack_name"></a> [stack\_name](#input\_stack\_name) | Stack name | `string` | `""` | no |
| <a name="input_stack_version"></a> [stack\_version](#input\_stack\_version) | Stack version | `string` | `"1.0.0"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Final tags map from Terragrunt stack layer | `map(string)` | `{}` | no |
| <a name="input_vm_groups"></a> [vm\_groups](#input\_vm\_groups) | Unused in this module; kept to allow unified stack inputs | `map(any)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_ct_instances"></a> [ct\_instances](#output\_ct\_instances) | Expanded CT instance map used to provision CTs |
| <a name="output_ct_names"></a> [ct\_names](#output\_ct\_names) | Provisioned CT hostnames |
<!-- END_TF_DOCS -->
