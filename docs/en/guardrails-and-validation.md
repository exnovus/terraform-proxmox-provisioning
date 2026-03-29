English | [Español](../es/guardrails-y-validacion.md) | [Docs index](README.md)

# Guardrails and Validation

## Scope of the public repository

This public repository does not ship custom wrappers for `plan` and `apply`. The recommended workflow uses Terragrunt directly so the execution path stays explicit and reviewable.

## Recommended flow

From the stack directory:

```bash
terragrunt init -upgrade
terragrunt validate
terragrunt plan -out=tfplan
```

Review the saved plan out of band, then apply exactly that file:

```bash
terragrunt apply tfplan
```

## Guardrails provided by the repository

- `root.hcl` generates `remote_state.tf` consistently and sets `-lock-timeout=5m`
- `providers.hcl` centralizes the `bpg/proxmox` provider
- `checks_sre.sh` protects the public architecture from regressions
- `.gitignore` blocks plans, generated provider/backend files, local state, and caches

## CI workflow shape

The workflow at `.github/workflows/ci.yml` runs on:

- `push` to `main` and `master`
- `pull_request` targeting `main` and `master`
- `workflow_dispatch`

It also uses one concurrency group per Git ref and cancels older runs for the same ref.

CI exports placeholder Proxmox variables such as `PM_API_URL`, `PM_USER`, `PM_PASSWORD=""`, and `PROXMOX_VE_ENDPOINT` with `pve.ci.invalid`. This keeps `init` and `validate` detached from any real API.

## CI coverage

The workflow at `.github/workflows/ci.yml` includes:

| Job | Purpose |
|-----|---------|
| `lint-and-guards` | Runs `bash -n`, `shellcheck -x`, verifies that `templates/envcommon/` only references `modules//components/`, and runs `./scripts/checks_sre.sh --fast` |
| `format` | Runs `terraform fmt -check -recursive modules/` and `terragrunt hcl format --check` |
| `fixture-validate` | Rebuilds `live/_envcommon/`, scaffolds `live/ci-test/datacenter-01/vm-fixture` and `ct-fixture`, runs `terragrunt init -upgrade -input=false` and `terragrunt validate`, and confirms tracked files stay unchanged |

CI does not run `apply`.

## What CI does not validate

- no real changes are applied to Proxmox
- no real credentials are checked
- remote state connectivity and migration are not validated
- `scripts/audit_state.sh` remains an operator-side check

## Local validation commands

Fast mode:

```bash
./scripts/checks_sre.sh --fast
```

Full mode:

```bash
./scripts/checks_sre.sh
```

Additional checks commonly used before a PR:

```bash
bash -n scripts/*.sh
bash scripts/audit_state.sh
terraform fmt -check -recursive modules/
terragrunt hcl format --check
```

## Anti-regression philosophy

- enforce the architecture rule: Terragrunt targets components, never resources
- keep tags wired through `tags-manager` and the workload tag list
- keep critical datacenter defaults and stack contract wiring intact
- keep `default_vm_id_base`, `default_ct_template`, and `default_ct_id_base` wired from YAML into the right component inputs
- confirm that scaffold scripts can rebuild `_envcommon` and validate a fixture tree
- ensure ignored runtime does not leak into version control
- keep private runtime and generated fixtures out of the tracked tree

## What must never be committed

- `tfplan*`
- `providers.tf`
- `remote_state.tf`
- `state/`
- `.terragrunt-cache/`

For the security-specific rules, see [security.md](security.md).
