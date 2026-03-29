[English](../en/scripts-and-scaffold.md) | Español | [Índice](README.md)

# Scripts y Scaffold

## Scripts disponibles

| Script | Propósito |
|--------|-----------|
| `create_environment.sh <env>` | Crea `live/<env>/` con `environment_vars.yaml` y un `terragrunt.hcl` mínimo |
| `create_environment_datacenter.sh <env> <dc>` | Crea `live/<env>/<dc>/` con `datacenter_vars.yaml` y un `terragrunt.hcl` mínimo |
| `create_environment_stack.sh <env> <dc> <stack> [vm\|ct]` | Crea un stack con `stack_vars.yaml` y un `terragrunt.hcl` que incluye `root`, `providers` y el `_envcommon` correcto |
| `checks_sre.sh [--fast]` | Checks anti-regresión para arquitectura, wiring, defaults, formato, backend y validación de fixtures |
| `audit_state.sh` | Auditoría de solo lectura del layout de state, estados fuera de lugar y residuos en caché |

Helpers internos:

- `scripts/lib_envcommon.sh` hace bootstrap y validación de `live/_envcommon/`
- `scripts/lib_yaml.sh` centraliza el parsing y la normalización YAML para el scaffold

Estos helpers se cargan con `source` desde los scripts públicos. No están pensados como entrypoints directos.

## Flujo de scaffold

Desde la raíz del repositorio:

```bash
./scripts/create_environment.sh demo
./scripts/create_environment_datacenter.sh demo lab-01
./scripts/create_environment_stack.sh demo lab-01 vm-demo vm
```

Luego configurar acceso local a Proxmox y trabajar desde el stack:

```bash
cd live/demo/lab-01/vm-demo
terragrunt init -upgrade
terragrunt validate
terragrunt plan -out=tfplan
```

`terragrunt init` descarga providers desde el registry, así que local y CI necesitan conectividad saliente salvo que exista un mirror o cache de plugins.

Los archivos YAML generados son puntos de partida. Conviene revisarlos y adaptarlos al cluster antes del primer `plan`.

Para auditar el layout resultante del state:

```bash
bash scripts/audit_state.sh
```

## Flags soportados y reglas de naming

- los scripts de scaffold aceptan `--force`
- donde aplica, también aceptan `--dry-run`
- los nombres de environment, datacenter y stack deben cumplir `^[a-z0-9-]+$`

`--dry-run` no evita las dependencias entre capas:

- `create_environment_datacenter.sh` sigue requiriendo que exista el environment
- `create_environment_stack.sh` sigue requiriendo environment y datacenter previos

### Derivación de `datacenter_short`

`create_environment_datacenter.sh` escribe `datacenter_short` en `datacenter_vars.yaml` con estas reglas:

- nombres terminados en `-NN` derivan `dcNN`
- otros nombres se compactan a caracteres alfanuméricos en minúscula y se recortan a cuatro caracteres

Ese código corto forma parte del contrato de naming de instancias.

## Bootstrap de `_envcommon`

`create_environment.sh` asegura que `live/_envcommon/` exista copiando:

- `templates/envcommon/vm-service.hcl`
- `templates/envcommon/lxc-service.hcl`

La misma regeneración puede forzarse con `--force`.

Si `live/_envcommon/` falta al crear un stack, `create_environment_stack.sh` intenta bootstrapearlo antes de fallar.

## Origen de los defaults del scaffold

1. `config/datacenter-defaults.yaml` define los defaults canónicos del datacenter bajo `proxmox:`
2. `scripts/lib_yaml.sh` lee scalars y listas con `proxmox.*` y fallback legacy
3. `create_environment_datacenter.sh` escribe valores normalizados en `datacenter_vars.yaml`
4. `create_environment_stack.sh` vuelve a leer esos defaults hacia `stack_vars.yaml`
5. los stacks VM generados escriben `template`, `template_vm_id` y `use_clone: true`

Defaults relevantes persistidos por el scaffold:

- `default_node`
- `default_bridge`
- `default_storage`
- `default_pool`
- `default_vm_template`
- `default_template_vm_id`
- `default_vm_id_base`
- `default_ct_template`
- `default_ct_id_base`

## Presets de stack

`create_environment_stack.sh` genera contenido preset según el nombre del stack:

- presets VM: `k8s-masters`, `k8s-workers`, `longhorn` y el grupo genérico `primary`
- presets CT: `vpn-agent` y el grupo genérico `primary`

Los ejemplos públicos bajo `live/example/` se mantienen intencionalmente pequeños y legibles. Documentan el contrato, mientras que el scaffold se enfoca en producir un árbol inicial usable.

## Ejemplos curados vs scaffold generado

`live/example/` es un árbol público de referencia curado:

- coincide con los contratos públicos actuales
- no necesita ser una copia byte a byte de la salida del scaffold
- usa valores de muestra legibles como `datacenter_short: lab01`

El scaffold sigue sus propias reglas deterministas. Por ejemplo, `create_environment_datacenter.sh demo lab-01` deriva `datacenter_short: dc01`.

## Defaults públicos del scaffold

Un stack VM recién generado usa estos defaults salvo que los cambies antes:

- nodo: `pve01`
- bridge: `vmbr0`
- storage: `local-lvm`
- template: `ubuntu-2404-cloudinit`
- template VMID: `9000`
- base de VMIDs: `4000`

El scaffold de VM también deja activo `use_clone: true`.

Los defaults canónicos del datacenter mantienen `default_ct_template: null`.

El ejemplo público de datacenter fija un template CT explícito para que el stack CT de ejemplo sea autocontenido:

`local:vztmpl/debian-12-standard_12.7-1_amd64.tar.zst`

Para stacks CT generados:

- `os_template` se lee desde `datacenter_vars.yaml`
- si ese valor resuelve vacío, el scaffold usa como fallback el identificador del template Debian mostrado arriba
- si `datacenter_vars.yaml` mantiene explícitamente `default_ct_template: null`, ese contrato sigue necesitando un template real antes de planificar

## Modo estricto para defaults

Para exigir que `default_ct_id_base` sea un entero válido durante la generación del datacenter:

```bash
STRICT_DEFAULTS=true ./scripts/create_environment_datacenter.sh demo lab-01
```

Para el contrato YAML consumido por el scaffold, ver [configuracion.md](configuracion.md).
