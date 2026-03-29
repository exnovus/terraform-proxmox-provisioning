English | [Español](../es/README.md)

> English docs are the source of truth. Spanish translations may slightly lag behind.

# Documentation

Public technical documentation for the repository, focused on architecture, contracts, scaffold usage, validation, and safe operation.

| Document | Purpose |
|----------|---------|
| [getting-started.md](getting-started.md) | Official onboarding path for preparing configuration, creating the tree, and deploying first VM and CT stacks |
| [architecture.md](architecture.md) | Execution layers, architecture rule, inheritance, tags, and execution flow |
| [repository-structure.md](repository-structure.md) | Public repository shape and responsibilities of each top-level area |
| [configuration.md](configuration.md) | YAML contracts, Proxmox config resolution, backend, and state behavior |
| [scripts-and-scaffold.md](scripts-and-scaffold.md) | Scaffold scripts, defaults origin, and bootstrap flow |
| [guardrails-and-validation.md](guardrails-and-validation.md) | Safe `plan`/`apply` flow, CI coverage, and local checks |
| [operations.md](operations.md) | Public operational runbook, post-apply validation, recovery, and migration |
| [troubleshooting.md](troubleshooting.md) | Common errors and quick diagnostics |
| [security.md](security.md) | What must never be committed and the pre-PR security checklist |
| [glossary.md](glossary.md) | Repository terminology |

Additional references:

- Root overview: [../../README.md](../../README.md)
- Spanish root overview: [../../README.es.md](../../README.es.md)
- Terraform module interface docs: `modules/**/README.md`
- Public examples: `live/example/`
- Recommended first document: [getting-started.md](getting-started.md)
