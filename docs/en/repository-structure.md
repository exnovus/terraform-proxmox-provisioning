English | [Español](../es/estructura-del-repositorio.md) | [Docs index](README.md)

# Repository Structure

## Public repository shape

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

The public example tree is intentionally small, sanitized, and curated:

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

Runtime artifacts such as `state/`, `.terragrunt-cache/`, `.terraform.lock.hcl`, `tfplan`, `providers.tf`, and `remote_state.tf` are not part of the public repository.

The versioned example files document the public contract. They are reference files, not a byte-for-byte dump of scaffold output.

## Operational contract for `live/`

| Path | Versioned | Purpose |
|------|-----------|---------|
| `live/_envcommon/` | No | Generated artifact copied from `templates/envcommon/` |
| `live/example/` | Yes | Sanitized public examples |
| `live/ci-test/` | No | CI fixture tree rebuilt during validation |
| `live/sre-check/` | No | Local validation fixture tree used by `checks_sre.sh` |
| `live/<env>/...` created by users | Optional or private | Real user environments; must stay free of runtime artifacts and secrets before publication |

## Root files

| File | Purpose |
|------|---------|
| `config/datacenter-defaults.yaml` | Canonical scaffold defaults under the `proxmox:` block |
| `config/proxmox.example.hcl` | Public placeholder for Proxmox endpoint and non-secret settings |
| `config/backend.example.hcl` | Public placeholder for optional remote state configuration |
| `config/backend-dev.hcl` | Local fallback backend configuration used when `config/backend-<env>.hcl` is absent |
| `root.hcl` | Generates `remote_state.tf`, resolves backend mode, ensures local `state/`, and sets `-lock-timeout=5m` |
| `providers.hcl` | Generates the `bpg/proxmox` provider configuration |
| `.terraform-version` | Pinned Terraform version for the repository |
| `.gitignore` | Excludes local runtime, generated envcommon, state, plans, caches, and operational artifacts |

## Modules

| Area | Role |
|------|------|
| `modules/core/tags-manager` | Shared tagging and naming helper |
| `modules/resources/proxmox-vm` | Internal VM workload module |
| `modules/resources/proxmox-lxc` | Internal LXC workload module |
| `modules/components/vm-service` | Public Terragrunt entrypoint for VM stacks |
| `modules/components/lxc-service` | Public Terragrunt entrypoint for LXC stacks |

Each reusable module ships its own local `README.md` maintained with `terraform-docs`.

## Automation and documentation

| Path | Purpose |
|------|---------|
| `.github/workflows/ci.yml` | Lint, guardrails, formatting, and fixture validation |
| `docs/en/` | English technical documentation and source of truth |
| `docs/es/` | Spanish translation set |
| `scripts/checks_sre.sh` | Repository guardrails and fixture-based anti-regression checks |
| `scripts/audit_state.sh` | Read-only state layout audit |
| `scripts/lib_envcommon.sh` | `_envcommon` bootstrap and validation helper |
| `scripts/lib_yaml.sh` | Shared YAML parsing helper for scaffold scripts |

For the behavioral model behind this tree, see [architecture.md](architecture.md). For scaffold details, see [scripts-and-scaffold.md](scripts-and-scaffold.md).
