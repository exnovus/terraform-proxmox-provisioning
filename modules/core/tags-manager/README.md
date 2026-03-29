# tags-manager

Módulo auxiliar compartido para construir un identificador normalizado y un mapa de tags compatible con Proxmox.

Este módulo no es un punto de entrada de Terragrunt. Se usa desde los componentes para mantener una sola fuente de verdad de tagging y nomenclatura.

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

No providers.

## Modules

No modules.

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_client"></a> [client](#input\_client) | Client component for the generated id | `string` | n/a | yes |
| <a name="input_delimiter"></a> [delimiter](#input\_delimiter) | Delimiter to use when composing id | `string` | `"-"` | no |
| <a name="input_name"></a> [name](#input\_name) | Name component for the generated id | `string` | n/a | yes |
| <a name="input_stage"></a> [stage](#input\_stage) | Environment/stage (dev, qa, admin, prod) | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags to merge with generated core tags | `map(any)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_client"></a> [client](#output\_client) | Original client input |
| <a name="output_id"></a> [id](#output\_id) | Full normalized id |
| <a name="output_name"></a> [name](#output\_name) | Original name input |
| <a name="output_stage"></a> [stage](#output\_stage) | Original stage input |
| <a name="output_taglist"></a> [taglist](#output\_taglist) | Proxmox taglist string: key-value pairs sorted, distinct, joined by ; |
| <a name="output_tags"></a> [tags](#output\_tags) | All tags including Name (original format, not sanitized) |
| <a name="output_tags_no_name"></a> [tags\_no\_name](#output\_tags\_no\_name) | All tags excluding Name |
| <a name="output_tags_sanitized"></a> [tags\_sanitized](#output\_tags\_sanitized) | Sanitized tags map for Proxmox: lowercase keys/values, only [a-z0-9\_.:-] chars |
<!-- END_TF_DOCS -->
