[English](../en/configuration.md) | Español | [Índice](README.md)

# Configuración

Este documento cubre el contrato público de YAML por capa, la resolución de configuración Proxmox y el comportamiento de backend/state usado por el repositorio.

La interfaz Terraform de cada módulo está documentada junto al propio módulo en `modules/**/README.md`.

## Contratos YAML

Cada capa de `live/` define su propio archivo YAML:

- `environment_vars.yaml`
- `datacenter_vars.yaml`
- `stack_vars.yaml`

El HCL compartido en `_envcommon` lee esos archivos y los expone como inputs a Terraform.

### `environment_vars.yaml`

Ubicación: `live/<env>/environment_vars.yaml`

| Campo | Obligatorio | Descripción |
|------|-------------|-------------|
| `environment` | Sí | Identificador del entorno como `dev`, `qa` o `prod` |
| `client` | No | Identificador de cliente o proyecto. Default público: `example` |
| `owner` | No | Equipo responsable. Default público: `example-team` |
| `naming_delimiter` | No | Delimitador de nombres, por defecto `-` |
| `tags` | No | Tags globales del environment, sin secretos |

Ejemplo:

```yaml
environment: dev
client: example
owner: example-team
naming_delimiter: "-"
tags:
  Terraform: "true"
  Owner: example-team
```

### `datacenter_vars.yaml`

Ubicación: `live/<env>/<datacenter>/datacenter_vars.yaml`

| Campo | Obligatorio | Descripción |
|------|-------------|-------------|
| `datacenter` | Sí | Nombre largo del datacenter |
| `datacenter_short` | Sí | Código corto usado en naming |
| `proxmox` | No | Defaults de Proxmox como nodos, storage, templates y bases de IDs |
| `tags` | No | Tags específicos del datacenter |

Ejemplo:

```yaml
datacenter: lab-01
datacenter_short: lab01
proxmox:
  nodes:
    - pve01
  default_node: pve01
  default_bridge: vmbr0
  default_storage: local-lvm
  default_pool: null
  default_vm_template: ubuntu-2404-cloudinit
  default_template_vm_id: 9000
  default_vm_id_base: 4000
  default_ct_template: local:vztmpl/debian-12-standard_12.7-1_amd64.tar.zst
  default_ct_id_base: 200
tags: {}
```

Notas:

- el árbol público de ejemplo bajo `live/example/` usa `lab01` como `datacenter_short` legible
- el scaffold deriva `datacenter_short` automáticamente al crear un datacenter; ver [scripts-y-scaffold.md](scripts-y-scaffold.md)
- el scaffold prioriza `proxmox.nodes` y `proxmox.default_*`
- las claves legacy top-level se siguen leyendo por compatibilidad
- las definiciones duplicadas entre root y `proxmox:` se rechazan
- enteros quoted y valores `null` se normalizan antes de escribir el archivo
- `config/datacenter-defaults.yaml` mantiene `default_ct_template: null`; el ejemplo público fija un template Debian explícito para que el ejemplo CT sea autocontenido

### `stack_vars.yaml`

Ubicación: `live/<env>/<datacenter>/<stack>/stack_vars.yaml`

| Campo | Obligatorio | Descripción |
|------|-------------|-------------|
| `stack_name` | Sí | Nombre del stack como `vm-demo` |
| `stack_type` | Sí | `vm` o `ct` |
| `stack_version` | No | Versión del stack, default `1.0.0` |
| `role` | No | Rol usado en naming y tags; por defecto `stack_name` |
| `default_vm_id_base` | No | Base local de VMIDs que sobreescribe el default del datacenter |
| `default_ct_id_base` | No | Base local de CT IDs que sobreescribe el default del datacenter |
| `vm_groups` | Condicional | Obligatorio cuando `stack_type: vm` |
| `ct_groups` | Condicional | Obligatorio cuando `stack_type: ct` |
| `custom_tags` | No | Tags de stack con precedencia alta |

Ejemplo público VM:

```yaml
stack_name: vm-demo
stack_type: vm
stack_version: "1.0.0"
role: vm-demo

vm_groups:
  primary:
    enabled: true
    role: app
    count: 1
    cpu: 2
    ram_mb: 4096
    disk_gb: 40
    template: ubuntu-2404-cloudinit
    template_vm_id: 9000
    use_clone: true
    cloud_init_set_hostname: true
    target_nodes: []
    bridge: vmbr0
    storage: local-lvm

custom_tags: {}
```

Ejemplo público CT:

```yaml
stack_name: ct-demo
stack_type: ct
stack_version: "1.0.0"
role: ct-demo

ct_groups:
  primary:
    enabled: true
    role: dns
    count: 1
    cpu: 1
    ram_mb: 512
    disk_gb: 8
    os_template: local:vztmpl/debian-12-standard_12.7-1_amd64.tar.zst
    target_nodes: []
    bridge: vmbr0
    storage: local-lvm
    ipv4: dhcp

custom_tags: {}
```

Los ejemplos versionados son archivos de referencia curados. Los stacks generados por scaffold pueden traer nombres de preset distintos o defaults adicionales según el nombre del stack y los valores de cada capa.

## Contrato de `vm_groups`

| Campo | Obligatorio | Descripción |
|------|-------------|-------------|
| `enabled` | No | Habilita o deshabilita el grupo |
| `role` | Sí | Rol usado en naming y tags |
| `count` | Sí | Cantidad de VMs a expandir |
| `cpu` | Sí | vCPU por VM |
| `ram_mb` | Sí | Memoria dedicada en MiB |
| `disk_gb` | Sí | Tamaño del disco raíz cuando la VM no se clona desde un template con disco listo |
| `template` | No | Referencia nominal del template dentro del contrato del stack |
| `template_vm_id` | No | VMID real del template clonable en Proxmox |
| `use_clone` | No | Crea un clone cuando es `true` y `template_vm_id` existe |
| `target_nodes` | No | Lista de nodos para rotación |
| `node` | No | Nodo fijo cuando `target_nodes` está vacío |
| `bridge` | No | Bridge de red |
| `storage` | No | Storage backend |
| `pool` | No | Pool de Proxmox |
| `agent_enabled` | No | Habilita el QEMU guest agent |
| `wait_for_agent` | No | Controla si el provider espera por el guest agent |
| `agent_timeout` | No | Duración de espera cuando aplica |
| `cloud_init_set_hostname` | No | Publica `local-hostname` vía metadata cloud-init |
| `tags` | No | Tags del grupo |
| `custom_tags` | No | Tags adicionales del grupo |
| `extra_disks` | No | Discos adicionales por VM |

Muchos knobs opcionales de runtime heredan defaults del component cuando se omiten. El ejemplo público mantiene el YAML mínimo y solo fija los campos que hacen más legible el contrato.

### `vm_groups[*].extra_disks`

| Campo | Obligatorio | Descripción |
|------|-------------|-------------|
| `interface` | Sí | Interfaz SCSI como `scsi1` o `scsi2` |
| `datastore_id` | No | Storage específico del disco; hereda el storage del grupo cuando se omite |
| `size_gb` | Sí | Tamaño del disco en GiB |
| `iothread` | No | Activa iothread para ese disco |
| `discard` | No | Política de discard: `on`, `ignore` o `unmap` |
| `ssd` | No | Emulación SSD |

Reglas:

- `interface` debe usar `scsi1+`
- `scsi0` queda reservado para el disco del SO
- cada interfaz de disco adicional debe ser única dentro de la misma VM
- `size_gb` debe ser mayor que `0`

## Contrato de `ct_groups`

| Campo | Obligatorio | Descripción |
|------|-------------|-------------|
| `enabled` | No | Habilita o deshabilita el grupo |
| `role` | Sí | Rol usado en hostname y tags |
| `count` | Sí | Cantidad de contenedores a expandir |
| `cpu` | Sí | vCPU por contenedor |
| `ram_mb` | Sí | Memoria dedicada en MiB |
| `disk_gb` | Sí | Tamaño del root filesystem |
| `os_template` | No | Identificador completo del template LXC como `datastore:vztmpl/file.tar.zst` |
| `target_nodes` | No | Lista de nodos para rotación |
| `node` | No | Nodo fijo cuando `target_nodes` está vacío |
| `bridge` | No | Bridge de red |
| `storage` | No | Storage backend del rootfs |
| `pool` | No | Pool de Proxmox |
| `unprivileged` | No | Modo unprivileged |
| `onboot` | No | Controla `start_on_boot` |
| `start` | No | Controla `started` |
| `ipv4` | No | `dhcp` o una IPv4 CIDR estática |
| `ipv4_gateway` | No | Gateway IPv4 para direccionamiento estático |
| `tags` | No | Tags del grupo |
| `custom_tags` | No | Tags adicionales del grupo |

Igual que en VM, los campos omitidos heredan defaults del component. Los ejemplos públicos mantienen el contrato conciso y se enfocan en los settings que un usuario nuevo suele editar primero.

## Reglas de uso

- nunca colocar credenciales o secretos en YAML
- los tags con `null` se normalizan de forma segura
- `default_storage` debe existir en Proxmox y soportar el tipo de contenido correcto: `images` para VMs, `rootdir` para CTs
- los ejemplos públicos usan `ubuntu-2404-cloudinit` con VMID `9000` y el identificador del template Debian CT mostrado arriba
- `cloud_init_set_hostname: true` publica metadata NoCloud para alinear el hostname del guest con el naming Terraform
- el storage usado para metadata cloud-init debe soportar `snippets`
- `default_vm_id_base` y `default_ct_id_base` permiten reservar rangos locales por stack sin cambiar el contrato del datacenter
- un stack CT debe resolver un template real desde `proxmox.default_ct_template` o desde `ct_groups[*].os_template` antes de planificar

## Resolución de config Proxmox

El HCL compartido resuelve la configuración Proxmox de forma dinámica:

1. lee `environment`
2. busca `config/proxmox-${environment}.hcl`
3. puede permitir un fallback local privado como `config/proxmox-dev.hcl`
4. si no encuentra nada, deja `proxmox_cfg = {}`
5. deja que las variables de entorno sobreescriban endpoint y autenticación
6. usa `https://localhost:8006/` como endpoint efectivo cuando no hay otra definición

El repositorio público incluye `config/proxmox.example.hcl` como punto de partida saneado. Ese flujo mantiene usable `terragrunt validate` incluso cuando aún no existe un archivo real de config Proxmox.

## Backend y estado

### Modo por defecto: backend local por stack

- el estado local se guarda en `live/<env>/<datacenter>/<stack>/state/terraform.tfstate`
- `root.hcl` fuerza esa ruta cuando el backend remoto no está habilitado
- antes de `plan`, `apply` y `destroy`, un hook crea `state/` si hace falta
- `exclude_from_copy = ["state/**"]` evita copiar el state local a `.terragrunt-cache`

### Backend remoto opcional: S3 + DynamoDB

- se habilita explícitamente en `config/backend-<env>.hcl` con `backend_enabled = true`
- orden de resolución:
  1. `config/backend-${environment}.hcl`
  2. fallback `config/backend-dev.hcl`
  3. si ninguno habilita backend remoto, queda activo el backend local
- campos esperados: `s3_bucket`, `s3_region`, `dynamodb_table` y opcionalmente `s3_endpoint`
- las credenciales no se guardan en HCL
- `config/backend.example.hcl` es el placeholder público; `config/backend-dev.hcl` aporta un fallback local para desarrollo y validación en CI

### Formato de key remota

La key remota se construye como:

`{client}/{environment}/{path_relative_to_include()}/terraform.tfstate`

Ejemplo:

`example/dev/live/example/lab-01/vm-demo/terraform.tfstate`

### Locking y concurrencia

- `root.hcl` aplica `-lock-timeout=5m`
- DynamoDB gestiona el locking distribuido del backend remoto
- el backend local mantiene el lock en el contexto del stack

### Migración de local a remoto

1. crear bucket S3 y tabla DynamoDB
2. completar `config/backend-<env>.hcl` con valores reales
3. ejecutar `terragrunt init -reconfigure -migrate-state` por stack
4. verificar con `terragrunt state list`
5. borrar backups locales obsoletos solo después de verificar

### Auditoría de estado

Comando recomendado:

```bash
bash scripts/audit_state.sh
```

Modo estricto:

```bash
STRICT_CACHE=1 bash scripts/audit_state.sh
```

Para el comportamiento del scaffold y el origen de defaults, ver [scripts-y-scaffold.md](scripts-y-scaffold.md).
