[English](../en/architecture.md) | Español | [Índice](README.md)

# Arquitectura

Este repositorio está diseñado para equipos que necesitan IaC reutilizable para Proxmox, con contratos claros, naming predecible y una separación estricta entre entrypoints públicos y workloads internos.

## Capas de ejecución

La ejecución con Terragrunt se organiza en tres capas jerárquicas:

| Capa | Ruta típica | Responsabilidad |
|------|-------------|-----------------|
| `environment` | `live/<env>/` | Contexto global como `environment`, `client`, `owner`, delimitador de naming y tags base |
| `datacenter` | `live/<env>/<datacenter>/` | Defaults de Proxmox como nodos, bridge, storage, pool y templates |
| `stack` | `live/<env>/<datacenter>/<stack>/` | Unidad desplegable VM o CT con `stack_type`, `vm_groups` o `ct_groups` |

Cada capa mantiene su propio contrato YAML y un `terragrunt.hcl` mínimo. El stack hereda el contexto de environment y datacenter mediante `find_in_parent_folders()` y los inputs compuestos en `_envcommon`.

## Regla de arquitectura: components vs resources

- Terragrunt solo debe apuntar a `modules/components/vm-service`
- Terragrunt solo debe apuntar a `modules/components/lxc-service`
- Terragrunt nunca debe apuntar a `modules/resources/proxmox-vm`
- Terragrunt nunca debe apuntar a `modules/resources/proxmox-lxc`

La razón es estructural. Un component orquesta:

1. `modules/core/tags-manager`
2. el workload bajo `modules/resources/*`

Así se mantiene consistente el contrato público de tags, naming y composición de inputs.

## HCL compartido y herencia

`live/_envcommon/` contiene el HCL compartido usado por todos los stacks:

- lee `environment_vars.yaml`, `datacenter_vars.yaml` y `stack_vars.yaml`
- hace merge de tags con null-safety
- resuelve `config/proxmox-<env>.hcl`
- define `terraform.source` hacia `modules//components/vm-service` o `modules//components/lxc-service`
- pasa el contrato completo de inputs a los módulos Terraform

La fuente de verdad está en `templates/envcommon/`. `live/_envcommon/` es generado por el scaffold y puede regenerarse con `--force`.

### Reglas de resolución de archivos

- `find_in_parent_folders("environment_vars.yaml", "")` busca el contrato de environment subiendo desde el stack
- `find_in_parent_folders("datacenter_vars.yaml", "")` resuelve el contrato del datacenter
- `get_terragrunt_dir()` se usa para `stack_vars.yaml`, que es local al stack

Ejemplo desde `live/demo/lab-01/vm-demo`:

- `environment_vars.yaml` resuelve `live/demo/environment_vars.yaml`
- `datacenter_vars.yaml` resuelve `live/demo/lab-01/datacenter_vars.yaml`
- `stack_vars.yaml` se lee desde el directorio actual del stack

## Resolución dinámica de config Proxmox

El HCL compartido sigue este flujo:

1. lee `environment` desde `environment_vars.yaml`
2. busca `config/proxmox-${environment}.hcl`
3. si no existe, puede usar un fallback local privado como `config/proxmox-dev.hcl`
4. si no existe ningún archivo, deja el mapa vacío para que `validate` siga funcionando
5. da prioridad a las variables de entorno para endpoint y autenticación
6. usa `https://localhost:8006/` como endpoint efectivo cuando no hay otra definición

Variables de entorno soportadas por el contrato público:

- endpoint: `PROXMOX_VE_ENDPOINT` o `PM_API_URL`
- autenticación por token: `PROXMOX_VE_API_TOKEN` o `PM_API_TOKEN`
- autenticación por usuario/contraseña: `PROXMOX_VE_USERNAME` o `PM_USER`, más `PROXMOX_VE_PASSWORD` o `PM_PASSWORD`

El repositorio público incluye `config/proxmox.example.hcl` como placeholder saneado. Los archivos locales privados siguen siendo opcionales.

## Tags y naming

Los tags se componen con este orden de precedencia, de menor a mayor:

1. tags de environment
2. tags de datacenter
3. core tags generados en `_envcommon`
4. `custom_tags` del stack

El mapa resultante se pasa al component como `tags`. Luego el component ejecuta `tags-manager`, que:

- normaliza claves y valores a string
- los sanitiza para Proxmox
- expone `tags_sanitized` y `taglist`

Después el workload añade metadata por recurso como:

- `resource_type`
- `role`
- `group`
- `index`
- `template_os` para VMs clonadas

El patrón de naming de instancias es:

`{client}-{environment}-{datacenter_short}-{role}-{index2}`

Ejemplo:

`example-dev-lab01-app-01`

El delimitador por defecto es `-`, configurable con `naming_delimiter`.

`datacenter_short` proviene del contrato YAML del datacenter. El ejemplo público usa `lab01`, mientras que los valores generados por scaffold dependen del nombre del datacenter y de las reglas del script.

## Flujo de ejecución

1. El scaffold crea opcionalmente `live/<env>/`, `<datacenter>/` y `<stack>/`
2. `terragrunt init` resuelve includes, backend, provider y el source del component
3. `terragrunt validate` comprueba la configuración Terraform generada
4. `terragrunt plan -out=tfplan` genera un plan revisable
5. `terragrunt apply tfplan` aplica exactamente ese plan

## Diagrama de responsabilidades

```text
Terragrunt (desde live/<env>/<dc>/<stack>)
    -> include root.hcl
    -> include providers.hcl
    -> include _envcommon/vm-service.hcl o lxc-service.hcl
         -> lee contratos YAML
         -> compone tags y defaults
         -> resuelve config Proxmox
         -> apunta a modules//components/*
              -> el component ejecuta tags-manager + workload
              -> el workload crea recursos Proxmox
```

Para el contrato YAML por capa, ver [configuracion.md](configuracion.md). Para la forma pública del repo, ver [estructura-del-repositorio.md](estructura-del-repositorio.md).
