English | [Español](../es/primeros-pasos.md) | [Docs index](README.md)

# Getting Started

This guide is the recommended onboarding path for `terraform-proxmox-provisioning`. It covers the first-use flow for preparing local configuration, creating an environment tree, and deploying a first VM and a first LXC container with the current repository structure.

## Before you begin

### Required tools

| Tool | Purpose |
|------|---------|
| Terraform `1.10.5` | Pinned by `.terraform-version` |
| Terragrunt | Compatible with Terraform `1.10.5`; CI uses `0.99.1` |
| `git` | Repository workflow |
| `ripgrep` | Local validation checks |
| `shellcheck` | Shell linting before contributing |
| `jq` | Optional output inspection |
| `direnv` | Optional local loading of `.envrc` |

### Proxmox information to collect

Before planning any stack, collect the real values for:

- Proxmox API endpoint
- API token or username/password
- one or more target node names
- the network bridge used by your workloads
- storage for VM disks with `images` support
- storage for CT root filesystems with `rootdir` support
- the VM template name and its Proxmox VMID
- the full LXC template identifier, for example `local:vztmpl/debian-12-standard_12.7-1_amd64.tar.zst`

### Repository assumptions

- Terragrunt targets `modules/components/vm-service` and `modules/components/lxc-service`
- `modules/resources/*` are internal workloads
- `templates/envcommon/` is the shared HCL source of truth
- `live/_envcommon/` is generated and can be recreated
- `live/example/` is a reference tree, not an executable environment
- local state is the default backend mode
- remote state with S3 + DynamoDB is optional
- runtime credentials come from environment variables, not from versioned YAML or HCL

If you enable `cloud_init_set_hostname: true` for VM stacks, the current component contract expects a snippets-capable storage named `local`.

## Workflow order

Use the repository in this order:

1. review the public examples and choose naming conventions
2. prepare `config/proxmox-<environment>.hcl`
3. decide whether to keep local state or configure a remote backend
4. adjust `config/datacenter-defaults.yaml`
5. create the `environment`
6. create the `datacenter`
7. create one or more `stack` directories
8. fill the generated YAML with real infrastructure values
9. authenticate to Proxmox
10. run `init`, `validate`, `plan`, and `apply`

## Files you will customize

| Path | Purpose |
|------|---------|
| `config/proxmox-<environment>.hcl` | Local Proxmox endpoint, user, and TLS settings without secrets |
| `config/backend-<environment>.hcl` | Optional remote state backend settings |
| `config/datacenter-defaults.yaml` | Repository-wide scaffold defaults |
| `live/<environment>/environment_vars.yaml` | Environment metadata and base tags |
| `live/<environment>/<datacenter>/datacenter_vars.yaml` | Datacenter naming and Proxmox defaults |
| `live/<environment>/<datacenter>/<stack>/stack_vars.yaml` | Stack-specific workload definitions |

## 1. Review the public references

Start with these files:

- [../../README.md](../../README.md)
- [configuration.md](configuration.md)
- [scripts-and-scaffold.md](scripts-and-scaffold.md)
- [architecture.md](architecture.md)
- `config/proxmox.example.hcl`
- `config/backend.example.hcl`
- `config/datacenter-defaults.yaml`
- `live/example/`

The public examples under `live/example/` show the intended YAML contract. They are reference files only and do not include the executable `terragrunt.hcl` tree created by the scaffold.

## 2. Choose environment, datacenter, and stack names

Pick the names you will use before running the scaffold. Typical examples:

- environment: `dev`
- datacenter: `lab-01`
- VM stack: `vm-demo`
- CT stack: `ct-demo`

The scaffold only accepts lowercase alphanumeric characters plus hyphens: `^[a-z0-9-]+$`.

`create_environment_datacenter.sh` also derives `datacenter_short`. For example, `datacenter-01` becomes `dc01`. If you prefer a different short code such as `lab01`, edit `datacenter_vars.yaml` after generation.

## 3. Prepare the Proxmox config file

Create the file that matches your environment name. For a `dev` environment:

```bash
cp config/proxmox.example.hcl config/proxmox-dev.hcl
```

Example content:

```hcl
locals {
  pm_api_url      = "https://proxmox.example.internal:8006/api2/json"
  pm_user         = "automation@pam"
  pm_tls_insecure = false
}
```

Guidelines:

- do not store tokens or passwords in this file
- use this file for endpoint, optional username, and TLS behavior
- create `config/proxmox-<environment>.hcl` explicitly for every real environment instead of relying on `config/proxmox-dev.hcl` as a fallback

## 4. Choose the state backend mode

### Local state

No extra configuration is required. Each stack writes local state to:

`live/<environment>/<datacenter>/<stack>/state/terraform.tfstate`

This mode is suitable for a personal lab or a single-user workflow.

### Remote state

For shared or long-lived environments, create `config/backend-<environment>.hcl` from `config/backend.example.hcl` and enable it explicitly:

```hcl
locals {
  backend_enabled = true

  s3_bucket      = "example-org-tfstate-dev"
  s3_region      = "us-east-1"
  dynamodb_table = "example-org-tfstate-locks-dev"
  s3_endpoint    = ""
}
```

Keep AWS credentials outside the repository. If an environment-specific backend file does not exist, `root.hcl` falls back to `config/backend-dev.hcl`.

## 5. Review datacenter scaffold defaults

Inspect `config/datacenter-defaults.yaml` and adjust it to match your cluster:

- `proxmox.nodes`
- `default_node`
- `default_bridge`
- `default_storage`
- `default_pool`
- `default_vm_template`
- `default_template_vm_id`
- `default_vm_id_base`
- `default_ct_template`
- `default_ct_id_base`

If you keep `default_ct_template: null`, CT stacks must define a real template before planning.

## 6. Create the environment and datacenter

Create the environment:

```bash
./scripts/create_environment.sh dev
```

Then create the datacenter:

```bash
./scripts/create_environment_datacenter.sh dev lab-01
```

Review the generated files:

- `live/dev/environment_vars.yaml`
- `live/dev/lab-01/datacenter_vars.yaml`

Typical edits:

- replace `client: example` and `owner: example-team`
- set the real node list and bridge
- confirm the VM template name and VMID
- set `default_ct_template` if you want CT stacks to inherit it automatically
- adjust `datacenter_short` when the generated short code does not match your naming scheme

## 7. Create the first VM stack

Generate a VM stack:

```bash
./scripts/create_environment_stack.sh dev lab-01 vm-demo vm
```

Review `live/dev/lab-01/vm-demo/stack_vars.yaml`.

At minimum, confirm:

- `template`
- `template_vm_id`
- `use_clone`
- `target_nodes` or `node`
- `bridge`
- `storage`
- `tags`

The public example under `live/example/lab-01/vm-demo/stack_vars.example.yaml` is a good reference for a small VM stack.

Optional VM fields you may enable when your template supports them:

- `agent_enabled`
- `wait_for_agent`
- `agent_timeout`
- `cloud_init_set_hostname`
- `extra_disks`

## 8. Create the first CT stack

Generate a CT stack:

```bash
./scripts/create_environment_stack.sh dev lab-01 ct-demo ct
```

Review `live/dev/lab-01/ct-demo/stack_vars.yaml`.

At minimum, confirm:

- `os_template`
- `target_nodes` or `node`
- `bridge`
- `storage`
- `ipv4`
- `tags`

The public example under `live/example/lab-01/ct-demo/stack_vars.example.yaml` is the reference for a small CT stack.

`os_template` must resolve to a real Proxmox template identifier before planning.

## 9. Authenticate to Proxmox

Token authentication is the recommended path:

```bash
export PROXMOX_VE_ENDPOINT="https://<host>:8006/"
export PROXMOX_VE_API_TOKEN="<token>"
export PROXMOX_VE_INSECURE="false"
```

Username/password mode is also supported:

```bash
export PM_API_URL="https://<host>:8006/api2/json"
export PM_USER="<user@realm>"
export PM_PASSWORD="<secret>"
export PM_TLS_INSECURE="false"
```

### Optional local `.envrc` with direnv

`direnv` can load these variables automatically from an untracked `.envrc` in the repository root.

Install `direnv`:

- macOS with Homebrew: `brew install direnv`
- Linux with the system package manager, for example:
  - Debian or Ubuntu: `sudo apt-get install direnv`
  - Fedora: `sudo dnf install direnv`
  - Arch Linux: `sudo pacman -S direnv`

Enable the shell hook:

- Bash: `echo 'eval "$(direnv hook bash)"' >> ~/.bashrc`
- Zsh: `echo 'eval "$(direnv hook zsh)"' >> ~/.zshrc`

Example `.envrc`:

```bash
export PROXMOX_VE_ENDPOINT="https://<host>:8006/"
export PROXMOX_VE_API_TOKEN="<token>"
export PROXMOX_VE_INSECURE="false"
```

Then run:

```bash
direnv allow
direnv reload
```

For more detail, see [operations.md](operations.md) and [security.md](security.md).

## 10. Initialize, validate, plan, and apply

From the VM stack directory:

```bash
cd live/dev/lab-01/vm-demo
terragrunt init -upgrade
terragrunt validate
terragrunt plan -out=tfplan
terragrunt apply tfplan
```

From the CT stack directory:

```bash
cd live/dev/lab-01/ct-demo
terragrunt init -upgrade
terragrunt validate
terragrunt plan -out=tfplan
terragrunt apply tfplan
```

Review the saved plan before applying it. After the first apply, inspect outputs such as:

- `terragrunt output vm_names`
- `terragrunt output -json vm_instances`
- `terragrunt output ct_names`
- `terragrunt output -json ct_instances`

## 11. Recommended routine checks

Use these commands as part of a normal workflow:

```bash
bash scripts/checks_sre.sh --fast
bash scripts/audit_state.sh
bash -n scripts/*.sh
terraform fmt -check -recursive modules/
terragrunt hcl format --check
```

## Next documentation

- [operations.md](operations.md) for day-to-day operation and credential rotation
- [configuration.md](configuration.md) for YAML contracts and backend behavior
- [scripts-and-scaffold.md](scripts-and-scaffold.md) for scaffold defaults and presets
- [architecture.md](architecture.md) for execution layers and the component/resource boundary
- [security.md](security.md) for rules about secrets, runtime artifacts, and `.envrc`
