#!/usr/bin/env bash
# Creates the datacenter layer: live/<env>/<datacenter>/ with datacenter_vars.yaml and a
# minimal terragrunt.hcl (root + providers). Requires create_environment.sh to have run first.
set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
DATACENTER_DEFAULTS_FILE="${REPO_ROOT}/config/datacenter-defaults.yaml"

DRY_RUN=false
FORCE=false
SUMMARY=()

usage() {
  cat <<USAGE
Usage: ${SCRIPT_NAME} <env> <datacenter> [--dry-run] [--force]

Creates:
  live/<env>/<datacenter>/
  live/<env>/<datacenter>/datacenter_vars.yaml
  live/<env>/<datacenter>/terragrunt.hcl
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

derive_datacenter_short() {
  local dc="$1"

  if [[ "$dc" =~ -([0-9]+)$ ]]; then
    printf "dc%02d\n" "$((10#${BASH_REMATCH[1]}))"
    return
  fi

  local compact
  compact="$(echo "$dc" | tr -cd 'a-z0-9')"

  if [[ -z "$compact" ]]; then
    echo "dc00"
  else
    echo "${compact:0:4}"
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

read_defaults_scalar() {
  local key="$1"

  if [[ ! -f "$DATACENTER_DEFAULTS_FILE" ]]; then
    return 0
  fi

  yaml_read_scalar_with_fallback "$DATACENTER_DEFAULTS_FILE" "proxmox.${key}" "$key"
}

read_defaults_nodes() {
  yaml_read_nodes "$DATACENTER_DEFAULTS_FILE"
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

if [[ "${#ARGS[@]}" -ne 2 ]]; then
  usage
  exit 1
fi

ENVIRONMENT="${ARGS[0]}"
DATACENTER="${ARGS[1]}"
validate_name "$ENVIRONMENT"
validate_name "$DATACENTER"

LIVE_DIR="${REPO_ROOT}/live"
ENV_DIR="${LIVE_DIR}/${ENVIRONMENT}"
DC_DIR="${ENV_DIR}/${DATACENTER}"

PARENT_HCL="include \"root\" {
  path = find_in_parent_folders(\"root.hcl\")
}

include \"providers\" {
  path = find_in_parent_folders(\"providers.hcl\")
}"

if [[ ! -f "${ENV_DIR}/environment_vars.yaml" ]]; then
  log_error "Missing ${ENV_DIR}/environment_vars.yaml. Run create_environment.sh first."
  exit 1
fi

ensure_dir "$DC_DIR"

if [[ ! -f "${ENV_DIR}/terragrunt.hcl" ]]; then
  log_warn "${ENV_DIR}/terragrunt.hcl missing. Recreating."
  write_file "${ENV_DIR}/terragrunt.hcl" "$PARENT_HCL"
fi

DATACENTER_SHORT="$(derive_datacenter_short "$DATACENTER")"

DEFAULT_BRIDGE="$(read_defaults_scalar "default_bridge")"
DEFAULT_STORAGE="$(read_defaults_scalar "default_storage")"
DEFAULT_POOL="$(read_defaults_scalar "default_pool")"
DEFAULT_NODE="$(read_defaults_scalar "default_node")"
DEFAULT_CT_ID_BASE="$(read_defaults_scalar "default_ct_id_base")"
DEFAULT_VM_TEMPLATE="$(read_defaults_scalar "default_vm_template")"
DEFAULT_TEMPLATE_VM_ID="$(read_defaults_scalar "default_template_vm_id")"
DEFAULT_VM_ID_BASE="$(read_defaults_scalar "default_vm_id_base")"
DEFAULT_CT_TEMPLATE="$(read_defaults_scalar "default_ct_template")"

[[ -z "$DEFAULT_BRIDGE" ]] && DEFAULT_BRIDGE="vmbr0"
[[ -z "$DEFAULT_STORAGE" ]] && DEFAULT_STORAGE="local-lvm"
[[ -z "$DEFAULT_POOL" ]] && DEFAULT_POOL="null"
[[ -z "$DEFAULT_NODE" ]] && DEFAULT_NODE="null"
[[ -z "$DEFAULT_CT_ID_BASE" ]] && DEFAULT_CT_ID_BASE="200"
[[ -z "$DEFAULT_VM_TEMPLATE" ]] && DEFAULT_VM_TEMPLATE="ubuntu-2404-cloudinit"
[[ -z "$DEFAULT_TEMPLATE_VM_ID" ]] && DEFAULT_TEMPLATE_VM_ID="9000"
[[ -z "$DEFAULT_VM_ID_BASE" ]] && DEFAULT_VM_ID_BASE="4000"
[[ -z "$DEFAULT_CT_TEMPLATE" ]] && DEFAULT_CT_TEMPLATE="null"

DEFAULT_POOL="$(yaml_normalize_null_literal "$DEFAULT_POOL")"
DEFAULT_NODE="$(yaml_normalize_null_literal "$DEFAULT_NODE")"
DEFAULT_CT_ID_BASE="$(yaml_normalize_int_default "$DEFAULT_CT_ID_BASE" "200" "default_ct_id_base")"
DEFAULT_TEMPLATE_VM_ID="$(yaml_normalize_int_default "$DEFAULT_TEMPLATE_VM_ID" "9000" "default_template_vm_id")"
DEFAULT_VM_ID_BASE="$(yaml_normalize_int_default "$DEFAULT_VM_ID_BASE" "4000" "default_vm_id_base")"
if yaml_is_nullish "$DEFAULT_CT_TEMPLATE"; then
  DEFAULT_CT_TEMPLATE="$(yaml_normalize_null_literal "$DEFAULT_CT_TEMPLATE")"
else
  DEFAULT_CT_TEMPLATE="$(yaml_strip_quotes "$DEFAULT_CT_TEMPLATE")"
  if [[ "$DEFAULT_CT_TEMPLATE" =~ [[:space:]]:|:[[:space:]] ]]; then
    log_error "Invalid default_ct_template '${DEFAULT_CT_TEMPLATE}'. Use a Proxmox file identifier without spaces after ':', for example datastore:vztmpl/file.tar.zst."
    exit 1
  fi
fi

mapfile -t DEFAULT_NODES < <(read_defaults_nodes)
if [[ "${#DEFAULT_NODES[@]}" -eq 0 ]]; then
  if [[ -n "$DEFAULT_NODE" && "$DEFAULT_NODE" != "null" ]]; then
    DEFAULT_NODES=("$DEFAULT_NODE")
  else
    DEFAULT_NODES=("pve01")
  fi
fi

NODES_YAML=""
for node in "${DEFAULT_NODES[@]}"; do
  NODES_YAML="${NODES_YAML}    - ${node}"$'\n'
done
NODES_YAML="${NODES_YAML%$'\n'}"

datacenter_yaml="$(cat <<YAML
datacenter: ${DATACENTER}
datacenter_short: ${DATACENTER_SHORT}
proxmox:
  nodes:
${NODES_YAML}
  default_node: ${DEFAULT_NODE}
  default_bridge: ${DEFAULT_BRIDGE}
  default_storage: ${DEFAULT_STORAGE}
  default_pool: ${DEFAULT_POOL}
  default_vm_template: ${DEFAULT_VM_TEMPLATE}
  default_template_vm_id: ${DEFAULT_TEMPLATE_VM_ID}
  default_vm_id_base: ${DEFAULT_VM_ID_BASE}
  default_ct_template: ${DEFAULT_CT_TEMPLATE}
  default_ct_id_base: ${DEFAULT_CT_ID_BASE}
tags:
  Datacenter: ${DATACENTER}
YAML
)"

write_file "${DC_DIR}/datacenter_vars.yaml" "$datacenter_yaml"
write_file "${DC_DIR}/terragrunt.hcl" "$PARENT_HCL"

print_summary
