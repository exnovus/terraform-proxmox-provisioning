English | [Español](README.es.md)

> English docs are the source of truth. Spanish translations may slightly lag behind.

# terraform-proxmox-provisioning

Provision Proxmox virtual machines and LXC containers with Terragrunt and Terraform using an `environment -> datacenter -> stack` operating model.

## Project Overview

This repository provides a reusable Infrastructure as Code scaffold for Proxmox environments. It combines shared YAML contracts, generated Terragrunt configuration, reusable Terraform components, and repository guardrails so teams can create and operate VM and CT stacks with a predictable structure.

## Key Capabilities

- environment, datacenter, and stack layers with explicit YAML contracts
- public Terragrunt entrypoints under `modules/components/*`
- internal workload modules under `modules/resources/*`
- shared naming and tagging through `templates/envcommon/` and `modules/core/tags-manager`
- scaffold scripts for bootstrapping new environments and stacks
- local state by default, with optional S3 + DynamoDB remote state
- bilingual documentation for onboarding, configuration, operations, and security

## Start Here

For a first setup, start with the official onboarding guides:

- [Getting Started](docs/en/getting-started.md)
- [Primeros pasos](docs/es/primeros-pasos.md)

Recommended first steps:

1. review the public examples under `live/example/`
2. prepare `config/proxmox-<environment>.hcl`
3. create an environment, datacenter, and stack with the scaffold scripts
4. authenticate to Proxmox with environment variables or a local `.envrc`
5. run `terragrunt init`, `validate`, `plan`, and `apply` from the target stack

## Requirements

| Tool | Use |
|------|-----|
| Terraform `1.10.5` | Pinned by `.terraform-version` |
| Terragrunt | Compatible with Terraform `1.10.5`; CI uses `0.99.1` |
| `git` | Repository workflow |
| `ripgrep` | Local checks in `scripts/checks_sre.sh` |
| `shellcheck` | Shell linting before contribution |
| `jq` | Optional output inspection |
| `direnv` | Optional local loading of `.envrc` |

Runtime authentication is expected through environment variables:

- token mode: `PROXMOX_VE_ENDPOINT`, `PROXMOX_VE_API_TOKEN`, `PROXMOX_VE_INSECURE`
- username/password mode: `PM_API_URL`, `PM_USER`, `PM_PASSWORD`, `PM_TLS_INSECURE`

Do not commit real credentials.

## Local Environment Variables

`direnv` is an optional local workflow for loading repository-specific environment variables from an untracked `.envrc`.

Install `direnv`:

- macOS with Homebrew: `brew install direnv`
- Linux with the system package manager, for example:
  - Debian or Ubuntu: `sudo apt-get install direnv`
  - Fedora: `sudo dnf install direnv`
  - Arch Linux: `sudo pacman -S direnv`

Enable the shell hook:

- Bash: `echo 'eval "$(direnv hook bash)"' >> ~/.bashrc`
- Zsh: `echo 'eval "$(direnv hook zsh)"' >> ~/.zshrc`

Example local `.envrc`:

```bash
export PROXMOX_VE_ENDPOINT="https://<host>:8006/"
export PROXMOX_VE_API_TOKEN="<token>"
export PROXMOX_VE_INSECURE="false"
```

Then approve it locally:

```bash
direnv allow
```

`.envrc` and `.direnv/` stay local and are ignored by the repository. See [docs/en/getting-started.md](docs/en/getting-started.md) and [docs/en/operations.md](docs/en/operations.md) for the full workflow.

## Usage Model

| Layer | Typical path | Responsibility |
|-------|--------------|----------------|
| `environment` | `live/<env>/` | Global metadata such as `environment`, `client`, `owner`, delimiter, and base tags |
| `datacenter` | `live/<env>/<datacenter>/` | Proxmox defaults such as nodes, bridge, storage, pools, and templates |
| `stack` | `live/<env>/<datacenter>/<stack>/` | Deployable VM or CT unit with `vm_groups` or `ct_groups` |

Architecture rule:

- Terragrunt must only target `modules/components/vm-service`
- Terragrunt must only target `modules/components/lxc-service`
- `modules/resources/*` are internal workloads and must not be targeted directly by Terragrunt

## Repository Structure

| Path | Purpose |
|------|---------|
| `config/` | Public examples and environment-specific configuration files |
| `live/example/` | Sanitized YAML examples |
| `modules/components/` | Public Terragrunt entrypoints |
| `modules/resources/` | Internal Terraform workloads |
| `modules/core/` | Shared helpers such as `tags-manager` |
| `scripts/` | Scaffold, validation, and state audit scripts |
| `templates/envcommon/` | Canonical shared Terragrunt HCL |
| `docs/en/`, `docs/es/` | Bilingual technical documentation |

## Scripts and Scaffolding

| Script | Purpose |
|--------|---------|
| `scripts/create_environment.sh` | Creates an environment layer and bootstraps `live/_envcommon/` |
| `scripts/create_environment_datacenter.sh` | Creates a datacenter layer with Proxmox defaults |
| `scripts/create_environment_stack.sh` | Creates a VM or CT stack with the correct Terragrunt includes |
| `scripts/checks_sre.sh` | Runs repository guardrails and anti-regression checks |
| `scripts/audit_state.sh` | Audits state layout and stray runtime artifacts |

## Architecture

- `templates/envcommon/` is the shared HCL source of truth
- `live/_envcommon/` is generated and can be recreated
- `providers.hcl` generates the Proxmox provider configuration
- `root.hcl` manages local or remote state generation
- module-level interface docs live under `modules/**/README.md`

For the full model, see [docs/en/architecture.md](docs/en/architecture.md).

## Documentation

Primary entrypoints:

- [Getting Started](docs/en/getting-started.md)
- [Documentation Index (English)](docs/en/README.md)
- [Índice de documentación (Español)](docs/es/README.md)

| Topic | Document |
|------|----------|
| Getting started | [docs/en/getting-started.md](docs/en/getting-started.md) |
| Architecture | [docs/en/architecture.md](docs/en/architecture.md) |
| Repository structure | [docs/en/repository-structure.md](docs/en/repository-structure.md) |
| Configuration and contracts | [docs/en/configuration.md](docs/en/configuration.md) |
| Scripts and scaffold | [docs/en/scripts-and-scaffold.md](docs/en/scripts-and-scaffold.md) |
| Guardrails and validation | [docs/en/guardrails-and-validation.md](docs/en/guardrails-and-validation.md) |
| Operations | [docs/en/operations.md](docs/en/operations.md) |
| Troubleshooting | [docs/en/troubleshooting.md](docs/en/troubleshooting.md) |
| Security | [docs/en/security.md](docs/en/security.md) |
| Glossary | [docs/en/glossary.md](docs/en/glossary.md) |

## Contributing

- Contribution guide: [CONTRIBUTING.md](CONTRIBUTING.md)
- Security policy: [SECURITY.md](SECURITY.md)
- Code of conduct: [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md)

## Author and Acknowledgments

This project was created by [exnovus](https://github.com/exnovus) through a technical mentoring process guided by [MefistoBaal](https://github.com/MefistoBaal). Appreciation is extended for the time, dedication, and technical guidance contributed during the development of the project.

The repository is shared openly with the community as a reference for learning, adoption, and continuous improvement.

## License

This project is released for community use under the license defined in this repository: [Apache-2.0](LICENSE).
