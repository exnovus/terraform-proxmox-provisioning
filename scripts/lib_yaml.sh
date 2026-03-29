#!/usr/bin/env bash
# Shared library for simple YAML parsing used by the scaffold.
# Must be loaded with source from other scripts; it is not executed directly.
# Public functions: yaml_read_scalar_with_fallback, yaml_read_nodes,
# yaml_normalize_null_literal, yaml_normalize_int_default, yaml_strip_quotes,
# yaml_is_nullish.

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  echo "[ERROR] scripts/lib_yaml.sh debe cargarse con source; no se ejecuta directamente." >&2
  exit 1
fi

yaml_trim_ws() {
  local s="${1-}"
  s="${s#"${s%%[![:space:]]*}"}"
  s="${s%"${s##*[![:space:]]}"}"
  printf "%s\n" "$s"
}

yaml_strip_quotes() {
  local value
  value="$(yaml_trim_ws "${1-}")"

  if [[ "${#value}" -ge 2 ]]; then
    local first_char="${value:0:1}"
    local last_char="${value: -1}"

    if [[ ( "$first_char" == '"' && "$last_char" == '"' ) || ( "$first_char" == "'" && "$last_char" == "'" ) ]]; then
      value="${value:1:${#value}-2}"
    fi
  fi

  value="$(yaml_trim_ws "$value")"
  printf "%s\n" "$value"
}

yaml_is_nullish() {
  local value=""
  value="$(yaml_strip_quotes "${1-}")"
  [[ -z "$value" || "${value,,}" == "null" ]]
}

yaml_read_scalar() {
  local file_path="$1"
  local path="$2"

  awk -v path="$path" '
    function ltrim(s) { sub(/^[[:space:]]+/, "", s); return s }
    function rtrim(s) { sub(/[[:space:]]+$/, "", s); return s }
    function trim(s)  { return rtrim(ltrim(s)) }

    BEGIN {
      depth = split(path, wanted, ".")
    }

    /^[[:space:]]*#/ || /^[[:space:]]*$/ { next }

    {
      raw = $0
      indent = match(raw, /[^ ]/) - 1
      if (indent < 0) {
        indent = 0
      }

      line = trim(raw)
      if (line !~ /^[^:]+:/) {
        next
      }

      yaml_key = trim(substr(line, 1, index(line, ":") - 1))
      value = trim(substr(line, index(line, ":") + 1))

      level = int(indent / 2) + 1
      keys[level] = yaml_key
      for (i = level + 1; i <= 16; i++) {
        delete keys[i]
      }

      if (level != depth || value == "") {
        next
      }

      matches = 1
      for (i = 1; i <= depth; i++) {
        if (keys[i] != wanted[i]) {
          matches = 0
          break
        }
      }

      if (matches) {
        sub(/[[:space:]]+#.*$/, "", value)
        print trim(value)
        exit
      }
    }
  ' "$file_path"
}

yaml_read_scalar_with_fallback() {
  local file_path="$1"
  local primary_path="$2"
  local legacy_path="$3"
  local value=""

  value="$(yaml_read_scalar "$file_path" "$primary_path")"
  if [[ -z "$value" && -n "$legacy_path" ]]; then
    value="$(yaml_read_scalar "$file_path" "$legacy_path")"
  fi

  printf "%s\n" "$value"
}

yaml_normalize_null_literal() {
  local value="${1-}"
  local normalized=""

  if yaml_is_nullish "$value"; then
    printf "null\n"
    return 0
  fi

  normalized="$(yaml_strip_quotes "$value")"
  printf "%s\n" "$normalized"
}

yaml_normalize_int_default() {
  local value="${1-}"
  local fallback="$2"
  local name="$3"
  local normalized=""

  if yaml_is_nullish "$value"; then
    printf "%s\n" "$fallback"
    return 0
  fi

  normalized="$(yaml_strip_quotes "$value")"
  if [[ "$normalized" =~ ^[0-9]+$ ]]; then
    printf "%s\n" "$normalized"
    return 0
  fi

  if [[ "$name" == "default_ct_id_base" && "${STRICT_DEFAULTS:-false}" == "true" ]]; then
    if declare -F log_error >/dev/null 2>&1; then
      log_error "Invalid ${name} '${value}' with STRICT_DEFAULTS=true. Expected integer or null."
    else
      echo "[ERROR] Invalid ${name} '${value}' with STRICT_DEFAULTS=true. Expected integer or null." >&2
    fi
    exit 1
  fi

  if declare -F log_warn >/dev/null 2>&1; then
    log_warn "Invalid ${name} '${value}'. Falling back to ${fallback}."
  else
    echo "[WARN] Invalid ${name} '${value}'. Falling back to ${fallback}."
  fi
  printf "%s\n" "$fallback"
}

yaml_read_nodes() {
  local file_path="$1"

  if [[ ! -f "$file_path" ]]; then
    return 0
  fi

  local proxmox_nodes=""

  proxmox_nodes="$(
    awk '
      function ltrim(s) { sub(/^[[:space:]]+/, "", s); return s }
      function rtrim(s) { sub(/[[:space:]]+$/, "", s); return s }
      function trim(s)  { return rtrim(ltrim(s)) }

      /^[[:space:]]*#/ || /^[[:space:]]*$/ { next }

      {
        raw = $0
        indent = match(raw, /[^ ]/) - 1
        if (indent < 0) {
          indent = 0
        }

        line = trim(raw)

        if (line == "proxmox:") {
          in_proxmox = 1
          proxmox_indent = indent
          in_nodes = 0
          next
        }

        if (in_proxmox && indent <= proxmox_indent && line != "proxmox:") {
          in_proxmox = 0
          in_nodes = 0
        }

        if (in_proxmox && line == "nodes:") {
          in_nodes = 1
          nodes_indent = indent
          next
        }

        if (in_nodes && indent > nodes_indent && line ~ /^-[[:space:]]*/) {
          sub(/^-[[:space:]]*/, "", line)
          sub(/[[:space:]]+#.*$/, "", line)
          line = trim(line)
          if (line != "") print line
          next
        }

        if (in_nodes && indent <= nodes_indent) {
          exit
        }
      }
    ' "$file_path"
  )"

  if [[ -n "$proxmox_nodes" ]]; then
    while IFS= read -r node; do
      node="$(yaml_strip_quotes "$node")"
      [[ -n "$node" ]] && printf "%s\n" "$node"
    done <<< "$proxmox_nodes"
    return 0
  fi

  awk '
    function ltrim(s) { sub(/^[[:space:]]+/, "", s); return s }
    function rtrim(s) { sub(/[[:space:]]+$/, "", s); return s }
    function trim(s)  { return rtrim(ltrim(s)) }

    /^[[:space:]]*#/ || /^[[:space:]]*$/ { next }

    {
      raw = $0
      indent = match(raw, /[^ ]/) - 1
      if (indent < 0) {
        indent = 0
      }

      line = trim(raw)

      if (indent == 0 && line == "nodes:") {
        in_nodes = 1
        nodes_indent = indent
        next
      }

      if (in_nodes && indent > nodes_indent && line ~ /^-[[:space:]]*/) {
        sub(/^-[[:space:]]*/, "", line)
        sub(/[[:space:]]+#.*$/, "", line)
        line = trim(line)
        if (line != "") print line
        next
      }

      if (in_nodes && indent <= nodes_indent) {
        exit
      }
    }
  ' "$file_path" | while IFS= read -r node; do
    node="$(yaml_strip_quotes "$node")"
    [[ -n "$node" ]] && printf "%s\n" "$node"
  done
}
