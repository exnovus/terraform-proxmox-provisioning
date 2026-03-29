[English](../en/guardrails-and-validation.md) | Español | [Índice](README.md)

# Guardrails y Validación

## Alcance del repositorio público

Este repositorio público no incluye wrappers propios para `plan` y `apply`. El flujo recomendado usa Terragrunt directamente para que la ejecución siga siendo explícita y revisable.

## Flujo recomendado

Desde el directorio del stack:

```bash
terragrunt init -upgrade
terragrunt validate
terragrunt plan -out=tfplan
```

Revisar el plan guardado fuera de banda y luego aplicar exactamente ese archivo:

```bash
terragrunt apply tfplan
```

## Guardrails que aporta el repositorio

- `root.hcl` genera `remote_state.tf` de forma consistente y fija `-lock-timeout=5m`
- `providers.hcl` centraliza el provider `bpg/proxmox`
- `checks_sre.sh` protege la arquitectura pública del repo contra regresiones
- `.gitignore` bloquea planes, archivos generados de provider/backend, state local y caches

## Forma del workflow de CI

El workflow en `.github/workflows/ci.yml` corre sobre:

- `push` a `main` y `master`
- `pull_request` hacia `main` y `master`
- `workflow_dispatch`

También usa un grupo de concurrencia por Git ref y cancela ejecuciones anteriores de la misma ref.

CI exporta variables placeholder de Proxmox como `PM_API_URL`, `PM_USER`, `PM_PASSWORD=""` y `PROXMOX_VE_ENDPOINT` con `pve.ci.invalid`. Eso mantiene `init` y `validate` desacoplados de una API real.

## Cobertura de CI

El workflow en `.github/workflows/ci.yml` incluye:

| Job | Propósito |
|-----|-----------|
| `lint-and-guards` | Ejecuta `bash -n`, `shellcheck -x`, comprueba que `templates/envcommon/` solo apunte a `modules//components/` y corre `./scripts/checks_sre.sh --fast` |
| `format` | Ejecuta `terraform fmt -check -recursive modules/` y `terragrunt hcl format --check` |
| `fixture-validate` | Regenera `live/_envcommon/`, crea `live/ci-test/datacenter-01/vm-fixture` y `ct-fixture`, ejecuta `terragrunt init -upgrade -input=false` y `terragrunt validate`, y confirma que los archivos versionados sigan intactos |

CI no ejecuta `apply`.

## Qué no valida el CI

- no aplica cambios reales en Proxmox
- no comprueba credenciales reales
- no valida conectividad ni migración de backend remoto
- `scripts/audit_state.sh` sigue siendo un check del operador

## Validación local

Modo rápido:

```bash
./scripts/checks_sre.sh --fast
```

Modo completo:

```bash
./scripts/checks_sre.sh
```

Checks adicionales habituales antes de un PR:

```bash
bash -n scripts/*.sh
bash scripts/audit_state.sh
terraform fmt -check -recursive modules/
terragrunt hcl format --check
```

## Filosofía anti-regresión

- hacer cumplir la regla de arquitectura: Terragrunt solo apunta a components
- mantener el wiring de tags a través de `tags-manager` y la `tags_list` del workload
- conservar el wiring de defaults críticos del datacenter y del contrato de stack
- mantener conectados `default_vm_id_base`, `default_ct_template` y `default_ct_id_base` desde YAML hacia los inputs correctos del component
- validar que el scaffold puede reconstruir `_envcommon` y pasar `init/validate` sobre un fixture
- evitar que el runtime ignorado termine versionado
- mantener fuera del árbol versionado el runtime privado y los fixtures generados

## Qué no debe versionarse nunca

- `tfplan*`
- `providers.tf`
- `remote_state.tf`
- `state/`
- `.terragrunt-cache/`

Para las reglas específicas de seguridad, ver [seguridad.md](seguridad.md).
