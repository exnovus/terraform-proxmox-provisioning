[English](README.md) | Español

> La documentación en inglés es la fuente de verdad. Las traducciones al español pueden quedar levemente desfasadas.

# terraform-proxmox-provisioning

Provisiona máquinas virtuales y contenedores LXC en Proxmox con Terragrunt y Terraform usando un modelo operativo `environment -> datacenter -> stack`.

## Visión General del Proyecto

Este repositorio ofrece un scaffold reutilizable de Infraestructura como Código para entornos Proxmox. Combina contratos YAML compartidos, configuración Terragrunt generada, componentes Terraform reutilizables y guardrails del repositorio para que los equipos puedan crear y operar stacks VM y CT con una estructura predecible.

## Capacidades Principales

- capas `environment`, `datacenter` y `stack` con contratos YAML explícitos
- entrypoints públicos de Terragrunt bajo `modules/components/*`
- módulos de workload internos bajo `modules/resources/*`
- naming y tagging compartidos mediante `templates/envcommon/` y `modules/core/tags-manager`
- scripts de scaffold para bootstrap de ambientes y stacks
- state local por defecto, con backend remoto opcional S3 + DynamoDB
- documentación bilingüe para onboarding, configuración, operación y seguridad

## Empieza Por Aquí

Para una primera puesta en marcha, comienza por las guías oficiales de onboarding:

- [Primeros pasos](docs/es/primeros-pasos.md)
- [Getting Started](docs/en/getting-started.md)

Pasos recomendados:

1. revisar los ejemplos públicos bajo `live/example/`
2. preparar `config/proxmox-<environment>.hcl`
3. crear `environment`, `datacenter` y `stack` con los scripts de scaffold
4. autenticar contra Proxmox con variables de entorno o con un `.envrc` local
5. ejecutar `terragrunt init`, `validate`, `plan` y `apply` desde el stack objetivo

## Requisitos

| Herramienta | Uso |
|-------------|-----|
| Terraform `1.10.5` | Fijado por `.terraform-version` |
| Terragrunt | Compatible con Terraform `1.10.5`; CI usa `0.99.1` |
| `git` | Flujo de trabajo del repositorio |
| `ripgrep` | Checks locales en `scripts/checks_sre.sh` |
| `shellcheck` | Lint de shell antes de contribuir |
| `jq` | Inspección opcional de outputs |
| `direnv` | Carga local opcional de `.envrc` |

La autenticación de runtime se espera por variables de entorno:

- modo token: `PROXMOX_VE_ENDPOINT`, `PROXMOX_VE_API_TOKEN`, `PROXMOX_VE_INSECURE`
- modo usuario/contraseña: `PM_API_URL`, `PM_USER`, `PM_PASSWORD`, `PM_TLS_INSECURE`

No se deben versionar credenciales reales.

## Variables Locales de Entorno

`direnv` es un flujo local opcional para cargar variables de entorno específicas del repositorio desde un `.envrc` no versionado.

Instala `direnv`:

- macOS con Homebrew: `brew install direnv`
- Linux con el gestor de paquetes del sistema, por ejemplo:
  - Debian o Ubuntu: `sudo apt-get install direnv`
  - Fedora: `sudo dnf install direnv`
  - Arch Linux: `sudo pacman -S direnv`

Activa el hook del shell:

- Bash: `echo 'eval "$(direnv hook bash)"' >> ~/.bashrc`
- Zsh: `echo 'eval "$(direnv hook zsh)"' >> ~/.zshrc`

Ejemplo de `.envrc` local:

```bash
export PROXMOX_VE_ENDPOINT="https://<host>:8006/"
export PROXMOX_VE_API_TOKEN="<token>"
export PROXMOX_VE_INSECURE="false"
```

Luego autorízalo en local:

```bash
direnv allow
```

`.envrc` y `.direnv/` permanecen locales y están ignorados por el repositorio. Consulta [docs/es/primeros-pasos.md](docs/es/primeros-pasos.md) y [docs/es/operacion.md](docs/es/operacion.md) para el flujo completo.

## Modelo de Uso

| Capa | Ruta típica | Responsabilidad |
|------|-------------|-----------------|
| `environment` | `live/<env>/` | Metadata global como `environment`, `client`, `owner`, delimitador y tags base |
| `datacenter` | `live/<env>/<datacenter>/` | Defaults de Proxmox como nodos, bridge, storage, pools y templates |
| `stack` | `live/<env>/<datacenter>/<stack>/` | Unidad desplegable VM o CT con `vm_groups` o `ct_groups` |

Regla de arquitectura:

- Terragrunt solo debe apuntar a `modules/components/vm-service`
- Terragrunt solo debe apuntar a `modules/components/lxc-service`
- `modules/resources/*` son workloads internos y no deben ser target directo de Terragrunt

## Estructura del Repositorio

| Ruta | Propósito |
|------|-----------|
| `config/` | Ejemplos públicos y archivos de configuración por ambiente |
| `live/example/` | Ejemplos YAML saneados |
| `modules/components/` | Entrypoints públicos de Terragrunt |
| `modules/resources/` | Workloads internos de Terraform |
| `modules/core/` | Helpers compartidos como `tags-manager` |
| `scripts/` | Scripts de scaffold, validación y auditoría de state |
| `templates/envcommon/` | HCL compartido canónico de Terragrunt |
| `docs/en/`, `docs/es/` | Documentación técnica bilingüe |

## Scripts y Scaffold

| Script | Propósito |
|--------|-----------|
| `scripts/create_environment.sh` | Crea la capa de environment y bootstrap de `live/_envcommon/` |
| `scripts/create_environment_datacenter.sh` | Crea la capa de datacenter con defaults de Proxmox |
| `scripts/create_environment_stack.sh` | Crea un stack VM o CT con los includes correctos de Terragrunt |
| `scripts/checks_sre.sh` | Ejecuta guardrails y checks anti-regresión del repositorio |
| `scripts/audit_state.sh` | Audita el layout de state y artefactos de runtime |

## Arquitectura

- `templates/envcommon/` es la fuente de verdad del HCL compartido
- `live/_envcommon/` es generado y puede recrearse
- `providers.hcl` genera la configuración del provider Proxmox
- `root.hcl` gestiona la generación de state local o remoto
- la documentación de interfaz de módulos vive en `modules/**/README.md`

Para el modelo completo, consulta [docs/es/arquitectura.md](docs/es/arquitectura.md).

## Documentación

Entradas principales:

- [Índice de documentación (Español)](docs/es/README.md)
- [Getting Started](docs/en/getting-started.md)
- [Documentation Index (English)](docs/en/README.md)

| Tema | Documento |
|------|-----------|
| Primeros pasos | [docs/es/primeros-pasos.md](docs/es/primeros-pasos.md) |
| Arquitectura | [docs/es/arquitectura.md](docs/es/arquitectura.md) |
| Estructura del repositorio | [docs/es/estructura-del-repositorio.md](docs/es/estructura-del-repositorio.md) |
| Configuración y contratos | [docs/es/configuracion.md](docs/es/configuracion.md) |
| Scripts y scaffold | [docs/es/scripts-y-scaffold.md](docs/es/scripts-y-scaffold.md) |
| Guardrails y validación | [docs/es/guardrails-y-validacion.md](docs/es/guardrails-y-validacion.md) |
| Operación | [docs/es/operacion.md](docs/es/operacion.md) |
| Troubleshooting | [docs/es/troubleshooting.md](docs/es/troubleshooting.md) |
| Seguridad | [docs/es/seguridad.md](docs/es/seguridad.md) |
| Glosario | [docs/es/glosario.md](docs/es/glosario.md) |

## Contribución

- Guía de contribución: [CONTRIBUTING.md](CONTRIBUTING.md)
- Política de seguridad: [SECURITY.md](SECURITY.md)
- Código de conducta: [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md)

## Autoría y Agradecimientos

Este proyecto fue creado por [exnovus](https://github.com/exnovus) mediante un proceso de mentoría técnica guiado por [MefistoBaal](https://github.com/MefistoBaal). Se reconoce el tiempo, la dedicación y la guía técnica aportados durante el desarrollo del proyecto.

El repositorio se comparte abiertamente con la comunidad como referencia para aprendizaje, adopción y mejora continua.

## Licencia

Este proyecto se publica para uso de la comunidad bajo la licencia definida en este repositorio: [Apache-2.0](LICENSE).
