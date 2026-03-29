[English](../en/troubleshooting.md) | Español | [Índice](README.md)

# Troubleshooting

## Errores frecuentes

| Problema | Causa probable | Acción |
|----------|----------------|--------|
| `401 authentication failure` | Credenciales Proxmox incorrectas o no exportadas | Revisar `PROXMOX_VE_ENDPOINT` o `PM_API_URL`, y según el modo elegido las variables de token o de usuario/contraseña |
| Module not found o ruta incorrecta | Terragrunt no apunta al módulo component | `_envcommon/*.hcl` debe usar `modules//components/vm-service` o `modules//components/lxc-service` |
| Provider Proxmox no encontrado | Provider incorrecto o sin inicializar | Usar `bpg/proxmox` desde `providers.hcl` y correr `terragrunt init -upgrade` |
| `Invalid resource type proxmox_virtual_environment_vm` o `...container` | El contrato entre provider y módulos está desalineado | Verificar `providers.hcl` y `modules/resources/*/versions.tf` |
| `init` pide input | El backend o provider requieren inicialización o reconfiguración | Ejecutar `terragrunt init`, o `terragrunt init -reconfigure` si cambió el backend |
| Missing envcommon file | `live/_envcommon/` fue borrado o está incompleto | Regenerarlo con `./scripts/create_environment.sh <env> --force` |
| Backend changed, init required | La config efectiva del backend no coincide con la inicialización local | Ejecutar `terragrunt init -reconfigure`, o `-migrate-state` si hay migración real |
| `Error acquiring the state lock` | Otro proceso mantiene el lock | Confirmar que no haya otra ejecución activa; si es seguro, usar `terragrunt force-unlock <LOCK_ID>` |
| `error asking for approval: EOF` | `apply` interactivo sin TTY o sin plan guardado | Ejecutar primero `terragrunt plan -out=tfplan` y luego `terragrunt apply tfplan` |
| Falla clonación de VM o no aparece el template | `default_vm_template`, `default_template_vm_id` o `template_vm_id` no coinciden con un template real | Revisar `datacenter_vars.yaml` y `stack_vars.yaml` |
| `expected template_file_id to be a valid file identifier` | El stack CT usa un valor incompleto de `os_template` | Usar el identificador completo `datastore:vztmpl/file.tar.zst` |
| `volume '<template>' does not exist` | El template LXC configurado no está cargado en Proxmox | Verificar el archivo real disponible y ajustar el contrato |
| Storage, pool o node no encontrado | Los defaults públicos no coinciden con el cluster actual | Ajustar `config/datacenter-defaults.yaml` o `datacenter_vars.yaml` |
| No aparece IP en `terragrunt output` | Los outputs de VM exponen metadata, no IPs del guest | Consultar la IP desde la UI de Proxmox o vía API del guest agent |
| La VM se crea pero no aparece IP en Proxmox | El template no tiene `qemu-guest-agent`, el servicio no responde o `agent_enabled` está en `false` | Validar el template, el servicio dentro del guest y `agent_enabled` |
| `Warning: error waiting for network interfaces from QEMU agent` | El provider consultó el guest antes de que el agent publicara interfaces | Revisar `agent_enabled`, `wait_for_agent` y `agent_timeout`; validar el guest agent dentro de la VM |
| La VM anuncia el hostname del template por DHCP | La metadata cloud-init no se aplicó o el storage de snippets no está disponible | Verificar `cloud_init_set_hostname`, `meta_data_file_id`, soporte de `snippets` y estado de cloud-init dentro del guest |
| Falla la carga de metadata cloud-init o Proxmox rechaza el snippet | El storage de snippets no soporta `snippets` o no está disponible en el nodo objetivo | Confirmar capacidades del storage y visibilidad desde el nodo en Proxmox |
| El plan muestra reemplazo de VM al asociar metadata cloud-init | El provider trata `meta_data_file_id` como parte de la definición de la VM | Planificar una recreación controlada y validar hostname tras el apply |
| SSH falla con el usuario esperado | El template cloud-init usa otro usuario | Revisar la personalización del template y conectarse con el usuario real configurado |

## Validación rápida

Desde un stack:

```bash
terragrunt init -upgrade
terragrunt validate
terragrunt plan
```

Si `validate` falla, revisar sintaxis HCL/Terraform y los archivos resueltos por `find_in_parent_folders()`. Si `plan` falla por `401`, revisar primero las variables de entorno de Proxmox.
