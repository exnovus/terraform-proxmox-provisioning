# Security Policy

## Reporting a Vulnerability

Do not open a public issue for:

- exposed secrets
- reusable credentials
- sensitive endpoints or topology details
- bypasses that could destroy or modify infrastructure

Report the finding privately to the repository maintainer or to the security channel of the team operating it, including:

- a description of the problem
- the impact
- the affected paths
- the minimum steps required to reproduce it

## Scope

This policy covers:

- Terraform and Terragrunt modules
- scaffold and validation scripts
- public documentation
- versioned examples and configuration files

## Expectations

- do not disclose sensitive details publicly before remediation
- rotate any compromised credential immediately
- rewrite Git history if a secret was published

## Out of Scope

- issues caused by unversioned local credentials
- private user configurations outside this repository
- operational failures in third-party Proxmox environments
