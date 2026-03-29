# Contributing

This repository publishes a Terragrunt/Terraform scaffold for Proxmox and prioritizes changes that are small, reviewable, and compatible with the current architecture.

## Before Opening a PR

1. Keep the architecture rule: Terragrunt must only enter through `modules/components/vm-service` and `modules/components/lxc-service`.
2. Do not introduce direct references to `modules/resources/*` from Terragrunt or from `templates/envcommon/`.
3. Do not commit secrets, state files, `tfplan`, `providers.tf`, `remote_state.tf`, generated `_envcommon`, or local Terraform/Terragrunt runtime artifacts.
4. Keep examples and documentation aligned with the real repository contract.

## Recommended Workflow

1. Discuss major architecture or contract changes before implementing them.
2. Keep changes focused: code, examples, documentation, and related checks.
3. Run the following before opening a PR:

```bash
bash -n scripts/*.sh
./scripts/checks_sre.sh --fast
bash scripts/audit_state.sh
terraform fmt -check -recursive modules/
```

4. If the change affects the scaffold or public documentation, update `README.md`, `docs/`, and `live/example/` as needed.

## Acceptance Criteria

- No sensitive data or references to the maintainer's real environment.
- No breakage of the existing YAML/HCL contract.
- No unnecessary structural refactors.
- A clear explanation of the change and its operational impact.

## Issues and Discussions

- Use issues for reproducible bugs, documentation gaps, or narrowly scoped improvement proposals.
- For larger-scope changes, open a technical discussion first with the problem, the proposal, and the expected impact.
