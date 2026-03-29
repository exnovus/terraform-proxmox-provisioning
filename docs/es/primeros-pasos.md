[English](../en/getting-started.md) | Español | [Índice](README.md)

# Primeros Pasos

Esta guía es la ruta de onboarding recomendada para `terraform-proxmox-provisioning`. Cubre el flujo de primer uso para preparar configuración local, crear el árbol de ambientes y desplegar una primera VM y un primer contenedor LXC con la estructura actual del repositorio.

## Antes de empezar

### Herramientas requeridas

| Herramienta | Propósito |
|-------------|-----------|
| Terraform `1.10.5` | Fijado por `.terraform-version` |
| Terragrunt | Compatible con Terraform `1.10.5`; CI usa `0.99.1` |
| `git` | Flujo de trabajo del repositorio |
| `ripgrep` | Checks locales de validación |
| `shellcheck` | Lint de shell antes de contribuir |
| `jq` | Inspección opcional de outputs |
| `direnv` | Carga local opcional de `.envrc` |

### Información de Proxmox que debes recopilar

Antes de planificar cualquier stack, reúne los valores reales de:

- endpoint del API de Proxmox
- token API o usuario/contraseña
- uno o más nombres de nodos destino
- bridge de red usado por tus cargas
- storage para discos VM con soporte `images`
- storage para root filesystem de CT con soporte `rootdir`
- nombre del template VM y su VMID en Proxmox
- identificador completo del template LXC, por ejemplo `local:vztmpl/debian-12-standard_12.7-1_amd64.tar.zst`

### Supuestos del repositorio

- Terragrunt apunta a `modules/components/vm-service` y `modules/components/lxc-service`
- `modules/resources/*` son workloads internos
- `templates/envcommon/` es la fuente de verdad del HCL compartido
- `live/_envcommon/` es generado y puede recrearse
- `live/example/` es un árbol de referencia, no un ambiente ejecutable
- el state local es el modo de backend por defecto
- el backend remoto con S3 + DynamoDB es opcional
- las credenciales de runtime vienen de variables de entorno, no de YAML o HCL versionado

Si activas `cloud_init_set_hostname: true` para stacks VM, el contrato actual del componente espera un storage con soporte `snippets` llamado `local`.

## Orden de uso

Usa el repositorio en este orden:

1. revisar los ejemplos públicos y definir convenciones de naming
2. preparar `config/proxmox-<environment>.hcl`
3. decidir si mantendrás state local o configurarás backend remoto
4. ajustar `config/datacenter-defaults.yaml`
5. crear el `environment`
6. crear el `datacenter`
7. crear uno o más `stack`
8. completar los YAML generados con valores reales de infraestructura
9. autenticar contra Proxmox
10. ejecutar `init`, `validate`, `plan` y `apply`

## Archivos que vas a personalizar

| Ruta | Propósito |
|------|-----------|
| `config/proxmox-<environment>.hcl` | Endpoint local de Proxmox, usuario y TLS sin secretos |
| `config/backend-<environment>.hcl` | Settings opcionales de backend remoto |
| `config/datacenter-defaults.yaml` | Defaults globales del scaffold |
| `live/<environment>/environment_vars.yaml` | Metadata del ambiente y tags base |
| `live/<environment>/<datacenter>/datacenter_vars.yaml` | Naming del datacenter y defaults de Proxmox |
| `live/<environment>/<datacenter>/<stack>/stack_vars.yaml` | Definiciones específicas del stack |

## 1. Revisa las referencias públicas

Empieza por estos archivos:

- [../../README.es.md](../../README.es.md)
- [configuracion.md](configuracion.md)
- [scripts-y-scaffold.md](scripts-y-scaffold.md)
- [arquitectura.md](arquitectura.md)
- `config/proxmox.example.hcl`
- `config/backend.example.hcl`
- `config/datacenter-defaults.yaml`
- `live/example/`

Los ejemplos públicos bajo `live/example/` muestran el contrato YAML esperado. Son archivos de referencia y no incluyen el árbol ejecutable de `terragrunt.hcl` que genera el scaffold.

## 2. Elige los nombres de environment, datacenter y stack

Define los nombres antes de ejecutar el scaffold. Ejemplos típicos:

- environment: `dev`
- datacenter: `lab-01`
- stack VM: `vm-demo`
- stack CT: `ct-demo`

El scaffold solo acepta minúsculas, números y guiones: `^[a-z0-9-]+$`.

`create_environment_datacenter.sh` también deriva `datacenter_short`. Por ejemplo, `datacenter-01` se convierte en `dc01`. Si prefieres otro código corto como `lab01`, edita `datacenter_vars.yaml` después de generarlo.

## 3. Prepara el archivo de configuración de Proxmox

Crea el archivo que coincida con el nombre de tu ambiente. Para un ambiente `dev`:

```bash
cp config/proxmox.example.hcl config/proxmox-dev.hcl
```

Contenido de ejemplo:

```hcl
locals {
  pm_api_url      = "https://proxmox.example.internal:8006/api2/json"
  pm_user         = "automation@pam"
  pm_tls_insecure = false
}
```

Reglas:

- no guardes tokens ni contraseñas en este archivo
- úsalo para endpoint, usuario opcional y comportamiento TLS
- crea `config/proxmox-<environment>.hcl` explícitamente para cada ambiente real en lugar de depender del fallback `config/proxmox-dev.hcl`

## 4. Elige el modo de backend de state

### State local

No requiere configuración adicional. Cada stack escribe el state local en:

`live/<environment>/<datacenter>/<stack>/state/terraform.tfstate`

Este modo encaja bien en laboratorio personal o flujo individual.

### State remoto

Para ambientes compartidos o de larga vida, crea `config/backend-<environment>.hcl` a partir de `config/backend.example.hcl` y actívalo explícitamente:

```hcl
locals {
  backend_enabled = true

  s3_bucket      = "example-org-tfstate-dev"
  s3_region      = "us-east-1"
  dynamodb_table = "example-org-tfstate-locks-dev"
  s3_endpoint    = ""
}
```

Mantén las credenciales AWS fuera del repositorio. Si no existe el archivo específico del ambiente, `root.hcl` cae a `config/backend-dev.hcl`.

## 5. Revisa los defaults del datacenter

Inspecciona `config/datacenter-defaults.yaml` y ajústalo al cluster:

- `proxmox.nodes`
- `default_node`
- `default_bridge`
- `default_storage`
- `default_pool`
- `default_vm_template`
- `default_template_vm_id`
- `default_vm_id_base`
- `default_ct_template`
- `default_ct_id_base`

Si mantienes `default_ct_template: null`, los stacks CT deben definir un template real antes de planificar.

## 6. Crea el environment y el datacenter

Crea el environment:

```bash
./scripts/create_environment.sh dev
```

Después crea el datacenter:

```bash
./scripts/create_environment_datacenter.sh dev lab-01
```

Revisa los archivos generados:

- `live/dev/environment_vars.yaml`
- `live/dev/lab-01/datacenter_vars.yaml`

Ediciones típicas:

- reemplazar `client: example` y `owner: example-team`
- fijar la lista real de nodos y el bridge
- confirmar nombre y VMID del template VM
- definir `default_ct_template` si quieres que los CT lo hereden automáticamente
- ajustar `datacenter_short` cuando el valor generado no coincide con tu convención

## 7. Crea el primer stack VM

Genera un stack VM:

```bash
./scripts/create_environment_stack.sh dev lab-01 vm-demo vm
```

Revisa `live/dev/lab-01/vm-demo/stack_vars.yaml`.

Como mínimo, confirma:

- `template`
- `template_vm_id`
- `use_clone`
- `target_nodes` o `node`
- `bridge`
- `storage`
- `tags`

El ejemplo público en `live/example/lab-01/vm-demo/stack_vars.example.yaml` es la referencia para un stack VM pequeño.

Campos VM opcionales que puedes activar cuando tu template los soporte:

- `agent_enabled`
- `wait_for_agent`
- `agent_timeout`
- `cloud_init_set_hostname`
- `extra_disks`

## 8. Crea el primer stack CT

Genera un stack CT:

```bash
./scripts/create_environment_stack.sh dev lab-01 ct-demo ct
```

Revisa `live/dev/lab-01/ct-demo/stack_vars.yaml`.

Como mínimo, confirma:

- `os_template`
- `target_nodes` o `node`
- `bridge`
- `storage`
- `ipv4`
- `tags`

El ejemplo público en `live/example/lab-01/ct-demo/stack_vars.example.yaml` es la referencia para un stack CT pequeño.

`os_template` debe resolver a un identificador real de template Proxmox antes de planificar.

## 9. Autentica contra Proxmox

La autenticación por token es la ruta recomendada:

```bash
export PROXMOX_VE_ENDPOINT="https://<host>:8006/"
export PROXMOX_VE_API_TOKEN="<token>"
export PROXMOX_VE_INSECURE="false"
```

También se soporta usuario/contraseña:

```bash
export PM_API_URL="https://<host>:8006/api2/json"
export PM_USER="<user@realm>"
export PM_PASSWORD="<secret>"
export PM_TLS_INSECURE="false"
```

### `.envrc` local opcional con direnv

`direnv` puede cargar estas variables automáticamente desde un `.envrc` no versionado en la raíz del repositorio.

Instala `direnv`:

- macOS con Homebrew: `brew install direnv`
- Linux con el gestor de paquetes del sistema, por ejemplo:
  - Debian o Ubuntu: `sudo apt-get install direnv`
  - Fedora: `sudo dnf install direnv`
  - Arch Linux: `sudo pacman -S direnv`

Activa el hook del shell:

- Bash: `echo 'eval "$(direnv hook bash)"' >> ~/.bashrc`
- Zsh: `echo 'eval "$(direnv hook zsh)"' >> ~/.zshrc`

Ejemplo de `.envrc`:

```bash
export PROXMOX_VE_ENDPOINT="https://<host>:8006/"
export PROXMOX_VE_API_TOKEN="<token>"
export PROXMOX_VE_INSECURE="false"
```

Luego ejecuta:

```bash
direnv allow
direnv reload
```

Para más detalle, consulta [operacion.md](operacion.md) y [seguridad.md](seguridad.md).

## 10. Inicializa, valida, planifica y aplica

Desde el directorio del stack VM:

```bash
cd live/dev/lab-01/vm-demo
terragrunt init -upgrade
terragrunt validate
terragrunt plan -out=tfplan
terragrunt apply tfplan
```

Desde el directorio del stack CT:

```bash
cd live/dev/lab-01/ct-demo
terragrunt init -upgrade
terragrunt validate
terragrunt plan -out=tfplan
terragrunt apply tfplan
```

Revisa el plan guardado antes de aplicarlo. Tras el primer apply, inspecciona outputs como:

- `terragrunt output vm_names`
- `terragrunt output -json vm_instances`
- `terragrunt output ct_names`
- `terragrunt output -json ct_instances`

## 11. Checks recomendados de rutina

Usa estos comandos como parte del flujo normal:

```bash
bash scripts/checks_sre.sh --fast
bash scripts/audit_state.sh
bash -n scripts/*.sh
terraform fmt -check -recursive modules/
terragrunt hcl format --check
```

## Siguiente documentación

- [operacion.md](operacion.md) para operación diaria y rotación de credenciales
- [configuracion.md](configuracion.md) para contratos YAML y backend
- [scripts-y-scaffold.md](scripts-y-scaffold.md) para defaults y presets del scaffold
- [arquitectura.md](arquitectura.md) para capas de ejecución y límite entre components y resources
- [seguridad.md](seguridad.md) para reglas sobre secretos, artefactos de runtime y `.envrc`
