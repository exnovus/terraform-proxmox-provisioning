#!/usr/bin/env bash
# Shared helpers to bootstrap live/_envcommon from templates/envcommon.

_envcommon_log() {
  local level="$1"
  shift

  if declare -F "log_${level}" >/dev/null 2>&1; then
    "log_${level}" "$@"
    return
  fi

  case "$level" in
    info) printf '[INFO] %s\n' "$*" ;;
    warn) printf '[WARN] %s\n' "$*" ;;
    error) printf '[ERROR] %s\n' "$*" >&2 ;;
    *) printf '[INFO] %s\n' "$*" ;;
  esac
}

_envcommon_summary_add() {
  local item="$1"

  if declare -p SUMMARY >/dev/null 2>&1; then
    SUMMARY+=("$item")
  fi
}

_envcommon_validate_template() {
  local template_path="$1"

  if [[ ! -f "$template_path" ]]; then
    _envcommon_log error "Missing envcommon template: ${template_path}"
    return 1
  fi

  if [[ ! -s "$template_path" ]]; then
    _envcommon_log error "Empty envcommon template: ${template_path}"
    return 1
  fi
}

_envcommon_copy_template() {
  local source_path="$1"
  local dest_path="$2"
  local force_flag="${3:-false}"

  if [[ -f "$dest_path" && "$force_flag" != true ]]; then
    _envcommon_log info "Envcommon file already exists, skipping: ${dest_path}"
    return 0
  fi

  if [[ "${DRY_RUN:-false}" == true ]]; then
    echo "[DRY-RUN] cp ${source_path} ${dest_path}"
    return 0
  fi

  cp "$source_path" "$dest_path"
  _envcommon_log info "Bootstrapped envcommon file: ${dest_path}"
  _envcommon_summary_add "file:${dest_path}"
}

ensure_envcommon_dir() {
  local repo_root="$1"
  local force_flag="${2:-false}"
  local templates_dir="${repo_root}/templates/envcommon"
  local envcommon_dir="${repo_root}/live/_envcommon"
  local vm_template="${templates_dir}/vm-service.hcl"
  local lxc_template="${templates_dir}/lxc-service.hcl"

  _envcommon_validate_template "$vm_template"
  _envcommon_validate_template "$lxc_template"

  if [[ ! -d "$envcommon_dir" ]]; then
    if [[ "${DRY_RUN:-false}" == true ]]; then
      echo "[DRY-RUN] mkdir -p ${envcommon_dir}"
    else
      mkdir -p "$envcommon_dir"
      _envcommon_log info "Created directory: ${envcommon_dir}"
    fi
    _envcommon_summary_add "dir:${envcommon_dir}"
  else
    _envcommon_log info "Directory already exists: ${envcommon_dir}"
  fi

  _envcommon_copy_template "$vm_template" "${envcommon_dir}/vm-service.hcl" "$force_flag"
  _envcommon_copy_template "$lxc_template" "${envcommon_dir}/lxc-service.hcl" "$force_flag"

  if [[ "${DRY_RUN:-false}" == true ]]; then
    return 0
  fi

  assert_envcommon_ready "$repo_root"
}

assert_envcommon_ready() {
  local repo_root="$1"
  local envcommon_dir="${repo_root}/live/_envcommon"
  local missing=()

  for file_name in vm-service.hcl lxc-service.hcl; do
    if [[ ! -s "${envcommon_dir}/${file_name}" ]]; then
      missing+=("${envcommon_dir}/${file_name}")
    fi
  done

  if [[ "${#missing[@]}" -eq 0 ]]; then
    return 0
  fi

  _envcommon_log error "Envcommon bootstrap incomplete. Missing or empty files:"
  for path in "${missing[@]}"; do
    _envcommon_log error "  - ${path}"
  done
  _envcommon_log error "Check templates/envcommon/ and rerun the scaffold."
  return 1
}
