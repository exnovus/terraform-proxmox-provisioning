[English](../en/repository-structure.md) | Español | [Índice](README.md)

# Estructura del Repositorio

## Forma pública del repositorio

```text
.
├── .github/
│   └── workflows/
│       └── ci.yml
├── config/
│   ├── datacenter-defaults.yaml
│   ├── proxmox.example.hcl
│   ├── backend.example.hcl
│   └── backend-dev.hcl
├── docs/
│   ├── README.md
│   ├── en/
│   └── es/
├── live/
│   └── example/
├── modules/
│   ├── core/
│   ├── resources/
│   └── components/
├── scripts/
├── templates/
│   └── envcommon/
├── providers.hcl
├── root.hcl
├── .terraform-version
├── .gitignore
├── README.md
└── README.es.md
```

## `live/example/`

El árbol público de ejemplo es intencionalmente pequeño, saneado y curado:

```text
live/
└── example/
    ├── environment_vars.example.yaml
    └── lab-01/
        ├── datacenter_vars.example.yaml
        ├── vm-demo/
        │   └── stack_vars.example.yaml
        └── ct-demo/
            └── stack_vars.example.yaml
```

Los artefactos de runtime como `state/`, `.terragrunt-cache/`, `.terraform.lock.hcl`, `tfplan`, `providers.tf` y `remote_state.tf` no forman parte del árbol público.

Los archivos versionados de ejemplo documentan el contrato público. Son archivos de referencia, no una copia byte a byte de la salida del scaffold.

## Contrato operativo de `live/`

| Ruta | Versionado | Propósito |
|------|------------|-----------|
| `live/_envcommon/` | No | Artefacto generado desde `templates/envcommon/` |
| `live/example/` | Sí | Ejemplos públicos saneados |
| `live/ci-test/` | No | Árbol fixture de CI reconstruido durante la validación |
| `live/sre-check/` | No | Árbol fixture local usado por `checks_sre.sh` |
| `live/<env>/...` creados por usuarios | Opcional o privado | Entornos reales del usuario; deben mantenerse sin runtime ni secretos antes de publicar |

## Archivos raíz

| Archivo | Propósito |
|---------|-----------|
| `config/datacenter-defaults.yaml` | Defaults canónicos del scaffold bajo el bloque `proxmox:` |
| `config/proxmox.example.hcl` | Placeholder público para endpoint Proxmox y settings no sensibles |
| `config/backend.example.hcl` | Placeholder público para backend remoto opcional |
| `config/backend-dev.hcl` | Configuración fallback de backend local usada cuando no existe `config/backend-<env>.hcl` |
| `root.hcl` | Genera `remote_state.tf`, resuelve el backend, asegura `state/` local y fija `-lock-timeout=5m` |
| `providers.hcl` | Genera la configuración del provider `bpg/proxmox` |
| `.terraform-version` | Versión de Terraform fijada para el repositorio |
| `.gitignore` | Excluye runtime local, envcommon generado, state, planes, caches y artefactos operativos |

## Módulos

| Área | Rol |
|------|-----|
| `modules/core/tags-manager` | Helper compartido de tagging y naming |
| `modules/resources/proxmox-vm` | Workload interno para VMs |
| `modules/resources/proxmox-lxc` | Workload interno para CTs |
| `modules/components/vm-service` | Entrypoint público de Terragrunt para stacks VM |
| `modules/components/lxc-service` | Entrypoint público de Terragrunt para stacks CT |

Cada módulo reutilizable incluye su propio `README.md` local mantenido con `terraform-docs`.

## Automatización y documentación

| Ruta | Propósito |
|------|-----------|
| `.github/workflows/ci.yml` | Lint, guardrails, formato y validación de fixtures |
| `docs/en/` | Documentación técnica en inglés y fuente de verdad |
| `docs/es/` | Conjunto traducido al español |
| `scripts/checks_sre.sh` | Guardrails del repositorio y checks anti-regresión basados en fixtures |
| `scripts/audit_state.sh` | Auditoría de solo lectura del layout de state |
| `scripts/lib_envcommon.sh` | Helper para bootstrap y validación de `_envcommon` |
| `scripts/lib_yaml.sh` | Helper compartido de parsing YAML para el scaffold |

Para el modelo de comportamiento detrás de este árbol, ver [arquitectura.md](arquitectura.md). Para el scaffold, ver [scripts-y-scaffold.md](scripts-y-scaffold.md).
