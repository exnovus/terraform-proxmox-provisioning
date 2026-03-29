#!/usr/bin/env bash
# Creates a stack (VM or CT) in live/<env>/<dc>/<stack>/ with stack_vars.yaml and a
# terragrunt.hcl with 3 includes (root, providers, _envcommon/vm-service or lxc-service).
# If live/_envcommon/ is missing, it attempts to bootstrap it from templates/envcommon/ and continue.
set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
# shellcheck source=scripts/lib_envcommon.sh
. "${SCRIPT_DIR}/lib_envcommon.sh"

DRY_RUN=false
FORCE=false
SUMMARY=()

usage() {
  cat <<USAGE
Usage: ${SCRIPT_NAME} <env> <datacenter> <stack> [vm|ct] [--dry-run] [--force]

Creates:
  live/<env>/<datacenter>/<stack>/
  live/<env>/<datacenter>/<stack>/stack_vars.yaml
  live/<env>/<datacenter>/<stack>/terragrunt.hcl
USAGE
}

log_info() { echo "[INFO] $*"; }
log_warn() { echo "[WARN] $*"; }
log_error() { echo "[ERROR] $*" >&2; }

# shellcheck source=scripts/lib_yaml.sh
. "${SCRIPT_DIR}/lib_yaml.sh"

validate_name() {
  local value="$1"
  if [[ ! "$value" =~ ^[a-z0-9-]+$ ]]; then
    log_error "Invalid name '$value'. Expected regex: ^[a-z0-9-]+$"
    exit 1
  fi
}

validate_stack_type() {
  local value="$1"
  if [[ "$value" != "vm" && "$value" != "ct" ]]; then
    log_error "Invalid stack type '$value'. Use vm or ct."
    exit 1
  fi
}

ensure_dir() {
  local dir_path="$1"

  if [[ -d "$dir_path" ]]; then
    log_info "Directory already exists: ${dir_path}"
    return
  fi

  if [[ "$DRY_RUN" == true ]]; then
    echo "[DRY-RUN] mkdir -p ${dir_path}"
  else
    mkdir -p "$dir_path"
    log_info "Created directory: ${dir_path}"
  fi

  SUMMARY+=("dir:${dir_path}")
}

write_file() {
  local file_path="$1"
  local content="$2"

  if [[ -f "$file_path" && "$FORCE" != true ]]; then
    log_error "File exists: ${file_path}. Use --force to overwrite."
    exit 1
  fi

  if [[ "$DRY_RUN" == true ]]; then
    if [[ -f "$file_path" ]]; then
      echo "[DRY-RUN] overwrite ${file_path}"
    else
      echo "[DRY-RUN] create ${file_path}"
    fi
  else
    printf "%s\n" "$content" > "$file_path"
    log_info "Wrote file: ${file_path}"
  fi

  SUMMARY+=("file:${file_path}")
}

print_summary() {
  echo
  echo "Summary"
  echo "-------"
  echo "Mode: $([[ "$DRY_RUN" == true ]] && echo "dry-run" || echo "apply")"
  echo "Force overwrite: ${FORCE}"
  for item in "${SUMMARY[@]}"; do
    echo "- ${item}"
  done
}

read_datacenter_scalar() {
  local file_path="$1"
  local key="$2"

  yaml_read_scalar_with_fallback "$file_path" "proxmox.${key}" "$key"
}

build_vm_groups_yaml() {
  case "$STACK" in
    k8s-masters)
      cat <<YAML
vm_groups:
  k8s_masters:
    enabled: true
    role: k8s-master
    count: 3
    cpu: 4
    ram_mb: 8192
    disk_gb: 80
    template: ${STACK_DEFAULT_VM_TEMPLATE}
    template_vm_id: ${STACK_DEFAULT_TEMPLATE_VM_ID}
    use_clone: true
    target_nodes: []
    bridge: ${STACK_DEFAULT_BRIDGE}
    storage: ${STACK_DEFAULT_STORAGE}
    tags:
      Component: control-plane
    custom_tags: {}
YAML
      ;;
    k8s-workers)
      cat <<YAML
vm_groups:
  k8s_workers:
    enabled: true
    role: k8s-worker
    count: 3
    cpu: 4
    ram_mb: 8192
    disk_gb: 120
    template: ${STACK_DEFAULT_VM_TEMPLATE}
    template_vm_id: ${STACK_DEFAULT_TEMPLATE_VM_ID}
    use_clone: true
    target_nodes: []
    bridge: ${STACK_DEFAULT_BRIDGE}
    storage: ${STACK_DEFAULT_STORAGE}
    tags:
      Component: worker
    custom_tags: {}
YAML
      ;;
    longhorn)
      cat <<YAML
vm_groups:
  longhorn:
    enabled: false
    role: longhorn
    count: 3
    cpu: 2
    ram_mb: 4096
    disk_gb: 200
    template: ${STACK_DEFAULT_VM_TEMPLATE}
    template_vm_id: ${STACK_DEFAULT_TEMPLATE_VM_ID}
    use_clone: true
    target_nodes: []
    bridge: ${STACK_DEFAULT_BRIDGE}
    storage: ${STACK_DEFAULT_STORAGE}
    tags:
      Component: storage
    custom_tags: {}
YAML
      ;;
    *)
      cat <<YAML
vm_groups:
  primary:
    enabled: true
    role: ${STACK}
    count: 1
    cpu: 2
    ram_mb: 4096
    disk_gb: 40
    template: ${STACK_DEFAULT_VM_TEMPLATE}
    template_vm_id: ${STACK_DEFAULT_TEMPLATE_VM_ID}
    use_clone: true
    target_nodes: []
    bridge: ${STACK_DEFAULT_BRIDGE}
    storage: ${STACK_DEFAULT_STORAGE}
    tags:
      Component: ${STACK}
    custom_tags: {}
YAML
      ;;
  esac
}

build_ct_groups_yaml() {
  case "$STACK" in
    vpn-agent)
      cat <<YAML
ct_groups:
  vpn_agent:
    enabled: true
    role: vpn-agent
    count: 1
    cpu: 1
    ram_mb: 512
    disk_gb: 8
    os_template: ${STACK_DEFAULT_CT_TEMPLATE}
    target_nodes: []
    bridge: ${STACK_DEFAULT_BRIDGE}
    storage: ${STACK_DEFAULT_STORAGE}
    tags:
      Component: edge
    custom_tags: {}
YAML
      ;;
    *)
      cat <<YAML
ct_groups:
  primary:
    enabled: true
    role: ${STACK}
    count: 1
    cpu: 1
    ram_mb: 512
    disk_gb: 8
    os_template: ${STACK_DEFAULT_CT_TEMPLATE}
    target_nodes: []
    bridge: ${STACK_DEFAULT_BRIDGE}
    storage: ${STACK_DEFAULT_STORAGE}
    tags:
      Component: ${STACK}
    custom_tags: {}
YAML
      ;;
  esac
}

ARGS=()
for arg in "$@"; do
  case "$arg" in
    --dry-run)
      DRY_RUN=true
      ;;
    --force)
      FORCE=true
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      ARGS+=("$arg")
      ;;
  esac
done

if [[ "${#ARGS[@]}" -lt 3 || "${#ARGS[@]}" -gt 4 ]]; then
  usage
  exit 1
fi

ENVIRONMENT="${ARGS[0]}"
DATACENTER="${ARGS[1]}"
STACK="${ARGS[2]}"
STACK_TYPE="${ARGS[3]:-vm}"

validate_name "$ENVIRONMENT"
validate_name "$DATACENTER"
validate_name "$STACK"
validate_stack_type "$STACK_TYPE"

ENVCOMMON_FILE="vm-service.hcl"
if [[ "$STACK_TYPE" == "ct" ]]; then
  ENVCOMMON_FILE="lxc-service.hcl"
fi

ENVCOMMON_PATH="${REPO_ROOT}/live/_envcommon/${ENVCOMMON_FILE}"
if [[ ! -s "$ENVCOMMON_PATH" ]]; then
  log_warn "Envcommon missing or empty: ${ENVCOMMON_PATH}. Bootstrapping from templates/envcommon/."
  ensure_envcommon_dir "$REPO_ROOT" "$FORCE"
fi

if [[ ! -s "$ENVCOMMON_PATH" ]]; then
  log_error "Missing envcommon file after bootstrap: ${ENVCOMMON_PATH}"
  log_error "Check templates/envcommon/${ENVCOMMON_FILE} and rerun the scaffold."
  exit 1
fi

LIVE_DIR="${REPO_ROOT}/live"
ENV_DIR="${LIVE_DIR}/${ENVIRONMENT}"
DC_DIR="${ENV_DIR}/${DATACENTER}"
STACK_DIR="${DC_DIR}/${STACK}"

if [[ ! -f "${ENV_DIR}/environment_vars.yaml" ]]; then
  log_error "Missing ${ENV_DIR}/environment_vars.yaml. Run create_environment.sh first."
  exit 1
fi

if [[ ! -f "${DC_DIR}/datacenter_vars.yaml" ]]; then
  log_error "Missing ${DC_DIR}/datacenter_vars.yaml. Run create_environment_datacenter.sh first."
  exit 1
fi

STACK_DEFAULT_BRIDGE="$(read_datacenter_scalar "${DC_DIR}/datacenter_vars.yaml" "default_bridge")"
STACK_DEFAULT_STORAGE="$(read_datacenter_scalar "${DC_DIR}/datacenter_vars.yaml" "default_storage")"
STACK_DEFAULT_VM_TEMPLATE="$(read_datacenter_scalar "${DC_DIR}/datacenter_vars.yaml" "default_vm_template")"
STACK_DEFAULT_TEMPLATE_VM_ID="$(read_datacenter_scalar "${DC_DIR}/datacenter_vars.yaml" "default_template_vm_id")"
STACK_DEFAULT_NODE="$(read_datacenter_scalar "${DC_DIR}/datacenter_vars.yaml" "default_node")"
STACK_DEFAULT_POOL="$(read_datacenter_scalar "${DC_DIR}/datacenter_vars.yaml" "default_pool")"
STACK_DEFAULT_CT_TEMPLATE="$(read_datacenter_scalar "${DC_DIR}/datacenter_vars.yaml" "default_ct_template")"

[[ -z "$STACK_DEFAULT_BRIDGE" ]] && STACK_DEFAULT_BRIDGE="vmbr0"
[[ -z "$STACK_DEFAULT_STORAGE" ]] && STACK_DEFAULT_STORAGE="local-lvm"
[[ -z "$STACK_DEFAULT_VM_TEMPLATE" ]] && STACK_DEFAULT_VM_TEMPLATE="ubuntu-2404-cloudinit"
[[ -z "$STACK_DEFAULT_TEMPLATE_VM_ID" ]] && STACK_DEFAULT_TEMPLATE_VM_ID="9000"
[[ -z "$STACK_DEFAULT_NODE" ]] && STACK_DEFAULT_NODE="pve01"
[[ -z "$STACK_DEFAULT_POOL" ]] && STACK_DEFAULT_POOL="null"
[[ -z "$STACK_DEFAULT_CT_TEMPLATE" ]] && STACK_DEFAULT_CT_TEMPLATE="local:vztmpl/debian-12-standard_12.7-1_amd64.tar.zst"

PARENT_HCL="include \"root\" {
  path = find_in_parent_folders(\"root.hcl\")
}

include \"providers\" {
  path = find_in_parent_folders(\"providers.hcl\")
}"

if [[ ! -f "${ENV_DIR}/terragrunt.hcl" ]]; then
  log_warn "${ENV_DIR}/terragrunt.hcl missing. Recreating."
  write_file "${ENV_DIR}/terragrunt.hcl" "$PARENT_HCL"
fi

if [[ ! -f "${DC_DIR}/terragrunt.hcl" ]]; then
  log_warn "${DC_DIR}/terragrunt.hcl missing. Recreating."
  write_file "${DC_DIR}/terragrunt.hcl" "$PARENT_HCL"
fi

ensure_dir "$STACK_DIR"

GROUPS_YAML=""
if [[ "$STACK_TYPE" == "ct" ]]; then
  GROUPS_YAML="$(build_ct_groups_yaml)"
else
  GROUPS_YAML="$(build_vm_groups_yaml)"
fi

stack_yaml="$(cat <<YAML
stack_name: ${STACK}
stack_type: ${STACK_TYPE}
stack_version: "1.0.0"
role: ${STACK}

${GROUPS_YAML}

custom_tags: {}
YAML
)"

stack_hcl="include \"root\" {
  path = find_in_parent_folders(\"root.hcl\")
}

include \"providers\" {
  path = find_in_parent_folders(\"providers.hcl\")
}

include \"envcommon\" {
  path = find_in_parent_folders(\"_envcommon/${ENVCOMMON_FILE}\")
}"

write_file "${STACK_DIR}/stack_vars.yaml" "$stack_yaml"
write_file "${STACK_DIR}/terragrunt.hcl" "$stack_hcl"

print_summary
