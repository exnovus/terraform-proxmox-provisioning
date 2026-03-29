English | [Español](../es/operacion.md) | [Docs index](README.md)

# Operations

This is the public runbook for bootstrapping an environment, validating stacks, rotating credentials, and recovering common repository-level situations.

## Bootstrap a new environment

1. Review scaffold defaults before generating the datacenter:

   ```bash
   sed -n '1,120p' config/datacenter-defaults.yaml
   ```

   The public files under `live/example/` are useful as a reference for the YAML contract and naming conventions.

2. Create the environment and datacenter:

   ```bash
   ./scripts/create_environment.sh demo
   ./scripts/create_environment_datacenter.sh demo lab-01
   ```

3. Create one or more stacks:

   ```bash
   ./scripts/create_environment_stack.sh demo lab-01 vm-demo vm
   ```

4. Review the generated YAML before the first plan:

   - adjust nodes, bridge, storage, and pool for your cluster
   - confirm the VM template name and template VMID
   - for CT stacks, make sure a real `os_template` is present either in `datacenter_vars.yaml` or in `stack_vars.yaml`

5. Export Proxmox access locally. Token auth is recommended:

   ```bash
   export PROXMOX_VE_ENDPOINT="https://<host>:8006/"
   export PROXMOX_VE_API_TOKEN="<token>"
   export PROXMOX_VE_INSECURE="true"
   ```

   Username/password mode remains supported:

   ```bash
   export PM_API_URL="https://<host>:8006/api2/json"
   export PM_USER="<user@realm>"
   export PM_PASSWORD="<secret>"
   export PM_TLS_INSECURE="true"
   ```

   `direnv` is a practical local alternative for these variables. Create an untracked `.envrc` instead of repeating `export` commands manually.

6. Initialize, validate, plan, and apply from the stack:

   ```bash
   cd live/demo/lab-01/vm-demo
   terragrunt init -upgrade
   terragrunt validate
   terragrunt plan -out=tfplan
   terragrunt apply tfplan
   ```

7. Audit the resulting state layout:

   ```bash
   bash scripts/audit_state.sh
   ```

## Optional local workflow with direnv

Install `direnv`:

- macOS with Homebrew: `brew install direnv`
- Linux with the system package manager, for example:
  - Debian or Ubuntu: `sudo apt-get install direnv`
  - Fedora: `sudo dnf install direnv`
  - Arch Linux: `sudo pacman -S direnv`

Enable the shell hook:

- Bash: `echo 'eval "$(direnv hook bash)"' >> ~/.bashrc`
- Zsh: `echo 'eval "$(direnv hook zsh)"' >> ~/.zshrc`

Create a local `.envrc` in the repository root:

```bash
export PROXMOX_VE_ENDPOINT="https://<host>:8006/"
export PROXMOX_VE_API_TOKEN="<token>"
export PROXMOX_VE_INSECURE="true"

# Optional remote backend credentials
# export AWS_ACCESS_KEY_ID="<access-key>"
# export AWS_SECRET_ACCESS_KEY="<secret-key>"
```

If you prefer username/password authentication, export `PM_API_URL`, `PM_USER`, `PM_PASSWORD`, and `PM_TLS_INSECURE` instead.

Approve it locally:

```bash
direnv allow
```

After editing `.envrc`, reload it:

```bash
direnv reload
```

The repository ignores both `.envrc` and `.direnv/`. Keep them local and review them as carefully as any other secret-bearing file.

## VM post-apply validation

The VM instance map is keyed as `<group>-NN`. The generic scaffold and the public VM example use `primary-01`.

1. Inspect VM metadata through Terragrunt outputs:

   ```bash
   cd live/demo/lab-01/vm-demo
   terragrunt output -json | jq '.vm_instances.value."primary-01" | {vm_id, vm_name, target_node, cloning, agent_enabled, wait_for_agent, cloud_init_set_hostname}'
   ```

2. Confirm in Proxmox that the VM exists and is running:

- UI: `Datacenter -> <node> -> <vmid> -> Summary`
- API: `GET /nodes/<node>/qemu/<vmid>/status/current`

3. If `cloud_init_set_hostname: true` is enabled, Proxmox attaches custom cloud-init metadata so the guest adopts the Terraform VM name.

4. If the template includes `qemu-guest-agent` and `agent_enabled: true`, Proxmox can expose guest interfaces through the agent. `wait_for_agent` controls whether Terraform waits for that signal.

5. Query the network interfaces from Proxmox when needed:

- UI: `Datacenter -> <node> -> <vmid> -> Summary`
- API: `GET /nodes/<node>/qemu/<vmid>/agent/network-get-interfaces`

6. Validate reachability and guest identity:

   ```bash
   timeout 5 bash -lc '</dev/tcp/<ip>/22' && echo ssh-port-open
   ssh <cloud-init-user>@<ip>
   hostnamectl --static
   cat /etc/hostname
   ```

7. Destroy the stack when the validation window is over:

   ```bash
   terragrunt destroy -auto-approve
   ```

## CT operational requirements

- the storage selected for CTs must support `rootdir`
- the LXC template must exist in Proxmox and use the full identifier form
- `config/datacenter-defaults.yaml` keeps `default_ct_template: null`
- the public example datacenter file sets an explicit Debian template to keep the CT example self-contained
- if the cluster uses different nodes, storage, or pools than the public defaults, adjust `config/datacenter-defaults.yaml` or `datacenter_vars.yaml` before the first apply

## Rotate Proxmox credentials

1. Rotate the credential in Proxmox according to the auth mode in use
2. Update the corresponding environment variable locally or in CI secrets
3. Run `terragrunt plan` in a stack to confirm connectivity

The repository does not store secrets in `config/proxmox-<env>.hcl`. Runtime credentials must come from the environment.

## Rotate AWS backend credentials

1. Rotate access keys in IAM
2. Update `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` in the runtime environment or CI secrets
3. Run `terragrunt init` in a stack to confirm access

## Recover after deleting `live/<env>` or `live/_envcommon`

- if only an environment tree was deleted, regenerate it with the scaffold scripts
- if `live/_envcommon/` is missing, `create_environment.sh <env> --force` recreates it from `templates/envcommon/`
- if local backend was in use, deleting `live/<env>/<dc>/<stack>/state/` removes the local state
- if remote backend was in use, the state remains in S3
- temporary trees such as `live/ci-test/` and `live/sre-check/` are regenerated by CI or local validation commands when needed

## Local to remote state migration

Summary:

1. create the S3 bucket and DynamoDB table
2. fill `config/backend-<env>.hcl`
3. run `terragrunt init -reconfigure -migrate-state` per stack
4. confirm with `terragrunt state list`

See [configuration.md](configuration.md) for the backend behavior in detail.
