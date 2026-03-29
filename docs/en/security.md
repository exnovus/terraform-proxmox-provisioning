English | [Español](../es/seguridad.md) | [Docs index](README.md)

# Security

## What must not be committed

- state files: `terraform.tfstate`, `terraform.tfstate.*`
- per-stack local state directories such as `*/state/`
- local runtime inside `live/`: `.terraform/`, `.terragrunt-cache/`, `.terraform.lock.hcl`, `terraform.tfstate*`, `tfplan*`, crash logs
- credentials: `PROXMOX_VE_API_TOKEN`, `PM_API_TOKEN`, `PROXMOX_VE_PASSWORD`, `PM_PASSWORD`, AWS credentials, or any other secret
- local secret files: `.env`, `.envrc`
- generated fixtures and recreated artifacts: `live/_envcommon/`, `live/sre-check/`, `live/ci-test/`

## What is safe to version

- `templates/envcommon/*` as the shared HCL source of truth
- declarative scaffold under `live/<env>/...` when it represents a clean public example or an intentionally versioned environment without secrets
- non-secret config such as `config/proxmox-<env>.hcl` and `config/backend-<env>.hcl`
- modules and scripts, except ignored generated artifacts

## Allowed patterns

- use environment variables for runtime secrets
- use CI secret stores for automation
- keep local `.envrc` usage strictly untracked
- use `direnv` with a local `.envrc` only for workstation convenience, never as a versioned project file

## Anti-patterns

- storing passwords or tokens in YAML or HCL
- storing passwords or tokens in a tracked `.envrc`
- committing state files or binary plans
- disabling TLS verification in production without an explicit documented reason
- publishing complete `terragrunt render --json` outputs when they may expose sensitive inputs

## Checklist before opening a PR

1. Run `./scripts/checks_sre.sh` or at least `./scripts/checks_sre.sh --fast`
2. Confirm Terragrunt does not reference `modules/resources/*` directly
3. Confirm no new `generate "tags"` logic was introduced in templates or live code
4. Review changed files for secrets or sensitive data
5. Run `bash scripts/audit_state.sh` to ensure no stray state files exist

## Vulnerability reporting

If you detect an exposed secret, report it privately and rotate the affected credential immediately. Do not open a public issue containing sensitive details.
