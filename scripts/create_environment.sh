#!/usr/bin/env bash
# Creates the environment layer in live/<env>/: environment_vars.yaml and a minimal
# terragrunt.hcl (root + providers). Also bootstraps live/_envcommon/ from templates/envcommon/
# so stacks can use it. Does not create a datacenter or stack; use the other scripts for that.
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
Usage: ${SCRIPT_NAME} <env> [--dry-run] [--force]

Creates:
  live/_envcommon/           (generado desde templates/envcommon/ si no existe o con --force)
  live/<env>/
  live/<env>/environment_vars.yaml
  live/<env>/terragrunt.hcl
USAGE
}

log_info() { echo "[INFO] $*"; }
log_warn() { echo "[WARN] $*"; }
log_error() { echo "[ERROR] $*" >&2; }

# Only alphanumeric names and hyphens to avoid problematic paths or YAML.
validate_name() {
  local value="$1"
  if [[ ! "$value" =~ ^[a-z0-9-]+$ ]]; then
    log_error "Invalid name '$value'. Expected regex: ^[a-z0-9-]+$"
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

if [[ "${#ARGS[@]}" -ne 1 ]]; then
  usage
  exit 1
fi

ENVIRONMENT="${ARGS[0]}"
validate_name "$ENVIRONMENT"

LIVE_DIR="${REPO_ROOT}/live"
ENV_DIR="${LIVE_DIR}/${ENVIRONMENT}"

ensure_dir "$LIVE_DIR"
ensure_envcommon_dir "$REPO_ROOT" "$FORCE"
ensure_dir "$ENV_DIR"
# Minimal environment_vars.yaml contract (no secrets).
environment_yaml="$(cat <<YAML
environment: ${ENVIRONMENT}
client: example
owner: example-team
naming_delimiter: "-"
tags:
  Terraform: "true"
  Owner: example-team
YAML
)"

# Ultra-light HCL: includes only; the logic lives in _envcommon (stacks only).
env_hcl="include \"root\" {
  path = find_in_parent_folders(\"root.hcl\")
}

include \"providers\" {
  path = find_in_parent_folders(\"providers.hcl\")
}"

write_file "${ENV_DIR}/environment_vars.yaml" "$environment_yaml"
write_file "${ENV_DIR}/terragrunt.hcl" "$env_hcl"

print_summary
