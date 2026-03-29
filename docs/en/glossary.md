English | [Español](../es/glosario.md) | [Docs index](README.md)

# Glossary

| Term | Definition |
|------|------------|
| Component | Terraform module under `modules/components/` that acts as the Terragrunt entrypoint and orchestrates `tags-manager` plus the workload module |
| Resource workload | Terraform module under `modules/resources/` that creates Proxmox resources and is never targeted directly by Terragrunt |
| tags-manager | Shared module under `modules/core/tags-manager` that normalizes, sanitizes, and formats tags for Proxmox |
| `_envcommon` | Shared HCL under `live/_envcommon/`, generated from `templates/envcommon/`, used to read YAML contracts and compose inputs |
| Stack | Deployable unit at `live/<env>/<datacenter>/<stack>/` |
| Scaffold | Scripted generation of the environment, datacenter, and stack directory tree |
| Guardrails | Execution constraints and regression checks that protect the public repository contract |
| Local backend | State stored per stack under `state/terraform.tfstate` |
| Remote backend | S3-compatible backend with DynamoDB locking, enabled through `config/backend-<env>.hcl` |
| State audit | Review performed by `scripts/audit_state.sh` to detect canonical state, stray state files, and cache leftovers |
| Architecture rule | Terragrunt only targets `modules/components/*`, never `modules/resources/*` |
| `find_in_parent_folders` | Terragrunt helper that searches for a file by walking up the directory tree |
| `get_repo_root()` | Terragrunt helper that returns the repository root and is used for absolute module source paths |
