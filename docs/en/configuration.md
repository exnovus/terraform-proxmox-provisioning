English | [Español](../es/configuracion.md) | [Docs index](README.md)

# Configuration

This document covers the public YAML-layer contract, Proxmox config resolution, and the backend/state behavior used by the repository.

The Terraform module interface itself is documented alongside each module under `modules/**/README.md`.

## YAML contracts

Each `live/` layer defines its own YAML file:

- `environment_vars.yaml`
- `datacenter_vars.yaml`
- `stack_vars.yaml`

The shared `_envcommon` HCL reads these files and exposes them as Terraform inputs.

### `environment_vars.yaml`

Location: `live/<env>/environment_vars.yaml`

| Field | Required | Description |
|------|----------|-------------|
| `environment` | Yes | Environment identifier such as `dev`, `qa`, or `prod` |
| `client` | No | Client or project identifier. Public default: `example` |
| `owner` | No | Owning team. Public default: `example-team` |
| `naming_delimiter` | No | Naming delimiter, default `-` |
| `tags` | No | Global environment tags without secrets |

Example:

```yaml
environment: dev
client: example
owner: example-team
naming_delimiter: "-"
tags:
  Terraform: "true"
  Owner: example-team
```

### `datacenter_vars.yaml`

Location: `live/<env>/<datacenter>/datacenter_vars.yaml`

| Field | Required | Description |
|------|----------|-------------|
| `datacenter` | Yes | Long datacenter name |
| `datacenter_short` | Yes | Short code used for naming |
| `proxmox` | No | Proxmox defaults such as nodes, storage, templates, and ID bases |
| `tags` | No | Datacenter-specific tags |

Example:

```yaml
datacenter: lab-01
datacenter_short: lab01
proxmox:
  nodes:
    - pve01
  default_node: pve01
  default_bridge: vmbr0
  default_storage: local-lvm
  default_pool: null
  default_vm_template: ubuntu-2404-cloudinit
  default_template_vm_id: 9000
  default_vm_id_base: 4000
  default_ct_template: local:vztmpl/debian-12-standard_12.7-1_amd64.tar.zst
  default_ct_id_base: 200
tags: {}
```

Notes:

- the public example tree under `live/example/` uses `lab01` as a readable `datacenter_short`
- the scaffold derives `datacenter_short` automatically when it creates a datacenter; see [scripts-and-scaffold.md](scripts-and-scaffold.md)
- the scaffold prioritizes `proxmox.nodes` and `proxmox.default_*`
- legacy top-level keys are still read for backward compatibility
- duplicated definitions across root and `proxmox:` are rejected by the scaffold guard
- quoted integers and `null` values are normalized before writing the file
- `config/datacenter-defaults.yaml` keeps `default_ct_template: null`; the public example sets an explicit Debian template so the CT example is self-contained

### `stack_vars.yaml`

Location: `live/<env>/<datacenter>/<stack>/stack_vars.yaml`

| Field | Required | Description |
|------|----------|-------------|
| `stack_name` | Yes | Stack name such as `vm-demo` |
| `stack_type` | Yes | `vm` or `ct` |
| `stack_version` | No | Stack version, default `1.0.0` |
| `role` | No | Naming/tagging role, defaults to `stack_name` |
| `default_vm_id_base` | No | Stack-local VMID base overriding the datacenter default |
| `default_ct_id_base` | No | Stack-local CT ID base overriding the datacenter default |
| `vm_groups` | Conditional | Required when `stack_type: vm` |
| `ct_groups` | Conditional | Required when `stack_type: ct` |
| `custom_tags` | No | Stack-level tags with high precedence |

Public VM example:

```yaml
stack_name: vm-demo
stack_type: vm
stack_version: "1.0.0"
role: vm-demo

vm_groups:
  primary:
    enabled: true
    role: app
    count: 1
    cpu: 2
    ram_mb: 4096
    disk_gb: 40
    template: ubuntu-2404-cloudinit
    template_vm_id: 9000
    use_clone: true
    cloud_init_set_hostname: true
    target_nodes: []
    bridge: vmbr0
    storage: local-lvm

custom_tags: {}
```

Public CT example:

```yaml
stack_name: ct-demo
stack_type: ct
stack_version: "1.0.0"
role: ct-demo

ct_groups:
  primary:
    enabled: true
    role: dns
    count: 1
    cpu: 1
    ram_mb: 512
    disk_gb: 8
    os_template: local:vztmpl/debian-12-standard_12.7-1_amd64.tar.zst
    target_nodes: []
    bridge: vmbr0
    storage: local-lvm
    ipv4: dhcp

custom_tags: {}
```

The versioned examples are curated reference files. Scaffold-generated stacks can contain different preset names or additional defaults depending on the stack name and layer values.

## `vm_groups` contract

| Field | Required | Description |
|------|----------|-------------|
| `enabled` | No | Enables or disables the group |
| `role` | Yes | Role used in naming and tags |
| `count` | Yes | Number of VMs to expand |
| `cpu` | Yes | vCPU per VM |
| `ram_mb` | Yes | Dedicated memory in MiB |
| `disk_gb` | Yes | Root disk size when the VM is not cloned from a ready-made template disk |
| `template` | No | Nominal template name kept in the stack contract |
| `template_vm_id` | No | Real Proxmox VMID of the cloneable template |
| `use_clone` | No | Creates a clone when `true` and `template_vm_id` is available |
| `target_nodes` | No | Rotation list of nodes |
| `node` | No | Fixed node when `target_nodes` is empty |
| `bridge` | No | Network bridge |
| `storage` | No | Storage backend |
| `pool` | No | Proxmox pool |
| `agent_enabled` | No | Enables the QEMU guest agent |
| `wait_for_agent` | No | Controls whether the provider waits for the guest agent |
| `agent_timeout` | No | Wait duration when the guest agent wait applies |
| `cloud_init_set_hostname` | No | Publishes `local-hostname` through cloud-init metadata |
| `tags` | No | Group-level tags |
| `custom_tags` | No | Additional group-level tags |
| `extra_disks` | No | Additional per-VM disks |

Many optional runtime knobs inherit component defaults when omitted. The public example keeps the YAML minimal and only sets fields that make the contract easier to read.

### `vm_groups[*].extra_disks`

| Field | Required | Description |
|------|----------|-------------|
| `interface` | Yes | SCSI interface such as `scsi1` or `scsi2` |
| `datastore_id` | No | Disk-specific storage, inherits the group storage when omitted |
| `size_gb` | Yes | Disk size in GiB |
| `iothread` | No | Enables iothread for the disk |
| `discard` | No | Discard policy: `on`, `ignore`, or `unmap` |
| `ssd` | No | SSD emulation flag |

Rules:

- `interface` must use `scsi1+`
- `scsi0` is reserved for the OS disk
- each extra disk interface must be unique within the same VM
- `size_gb` must be greater than `0`

## `ct_groups` contract

| Field | Required | Description |
|------|----------|-------------|
| `enabled` | No | Enables or disables the group |
| `role` | Yes | Role used in hostname and tags |
| `count` | Yes | Number of containers to expand |
| `cpu` | Yes | vCPU per container |
| `ram_mb` | Yes | Dedicated memory in MiB |
| `disk_gb` | Yes | Root filesystem size |
| `os_template` | No | Full LXC template identifier such as `datastore:vztmpl/file.tar.zst` |
| `target_nodes` | No | Rotation list of nodes |
| `node` | No | Fixed node when `target_nodes` is empty |
| `bridge` | No | Network bridge |
| `storage` | No | Root filesystem storage backend |
| `pool` | No | Proxmox pool |
| `unprivileged` | No | Unprivileged container mode |
| `onboot` | No | Controls `start_on_boot` |
| `start` | No | Controls `started` |
| `ipv4` | No | `dhcp` or a static IPv4 CIDR |
| `ipv4_gateway` | No | IPv4 gateway for static addressing |
| `tags` | No | Group-level tags |
| `custom_tags` | No | Additional group-level tags |

As with VM stacks, omitted fields inherit component defaults. Public examples keep the contract concise and focus on the settings a new user typically edits first.

## Usage rules

- never place credentials or secrets in YAML
- tags with `null` values are normalized safely
- `default_storage` must exist in Proxmox and support the right content type: `images` for VMs, `rootdir` for CTs
- public examples use `ubuntu-2404-cloudinit` with template VMID `9000` and the Debian CT template identifier shown above
- `cloud_init_set_hostname: true` publishes NoCloud metadata so the guest hostname matches the Terraform naming
- the snippets storage used for custom cloud-init metadata must support `snippets`
- `default_vm_id_base` and `default_ct_id_base` let a stack reserve local ID ranges without changing the datacenter contract
- a CT stack must resolve a real template either from `proxmox.default_ct_template` or from `ct_groups[*].os_template` before planning

## Proxmox config resolution

The shared HCL resolves Proxmox configuration dynamically:

1. read `environment`
2. look for `config/proxmox-${environment}.hcl`
3. optionally allow a private local fallback such as `config/proxmox-dev.hcl`
4. if nothing exists, keep `proxmox_cfg = {}`
5. let runtime environment variables override endpoint and authentication
6. fall back to `https://localhost:8006/` as the effective endpoint when nothing else is defined

The public repository ships `config/proxmox.example.hcl` as a sanitized starting point. This lookup flow keeps `terragrunt validate` usable even when no real Proxmox config file exists yet.

## Backend and state

### Default mode: local backend per stack

- local state is stored at `live/<env>/<datacenter>/<stack>/state/terraform.tfstate`
- `root.hcl` forces that path when remote backend is not enabled
- before `plan`, `apply`, and `destroy`, a hook creates `state/` if needed
- `exclude_from_copy = ["state/**"]` avoids copying local state into `.terragrunt-cache`

### Optional remote backend: S3 + DynamoDB

- enable it explicitly in `config/backend-<env>.hcl` with `backend_enabled = true`
- resolution order:
  1. `config/backend-${environment}.hcl`
  2. fallback `config/backend-dev.hcl`
  3. if neither enables remote backend, local backend stays active
- expected fields: `s3_bucket`, `s3_region`, `dynamodb_table`, and optional `s3_endpoint`
- credentials are not stored in HCL
- `config/backend.example.hcl` is the public placeholder; `config/backend-dev.hcl` provides a local fallback for development and CI validation

### Remote key format

The remote key is built as:

`{client}/{environment}/{path_relative_to_include()}/terraform.tfstate`

Example:

`example/dev/live/example/lab-01/vm-demo/terraform.tfstate`

### Locking and concurrency

- `root.hcl` applies `-lock-timeout=5m`
- DynamoDB handles distributed locking for remote state
- local backend keeps the lock in the stack state context

### Local to remote migration

1. create the S3 bucket and DynamoDB table
2. fill `config/backend-<env>.hcl` with real values
3. run `terragrunt init -reconfigure -migrate-state` in each stack
4. verify with `terragrunt state list`
5. remove obsolete local state backups only after verification

### State audit

Recommended command:

```bash
bash scripts/audit_state.sh
```

Strict mode:

```bash
STRICT_CACHE=1 bash scripts/audit_state.sh
```

For scaffold behavior and defaults origin, see [scripts-and-scaffold.md](scripts-and-scaffold.md).
