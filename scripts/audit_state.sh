#!/usr/bin/env bash
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"

LIVE_DIR="$ROOT/live"
CONFIG_DIR="$ROOT/config"

echo "== Terragrunt/Terraform State Audit =="
echo "Repo root: $ROOT"
echo

if [[ ! -d "$LIVE_DIR" ]]; then
  echo "ERROR: No existe el directorio live/ en: $LIVE_DIR"
  exit 1
fi

# 1) Detect terragrunt.hcl (excluding cache)
mapfile -t TG_FILES < <(
  find live \
    -path '*/.terragrunt-cache/*' -prune -o \
    -name terragrunt.hcl -print | sort
)

echo "Terragrunt.hcl encontrados (excluyendo cache): ${#TG_FILES[@]}"
printf '%s\n' "${TG_FILES[@]}" | sed 's/^/ - /'
echo

# 2) Leaf stacks: directories with terragrunt.hcl and no terragrunt.hcl in subdirectories (excluding cache)
declare -a STACK_DIRS=()
for f in "${TG_FILES[@]}"; do
  d="$(dirname "$f")"

  # If another terragrunt.hcl exists further down (mindepth>=2) => it is not a leaf
  if find "$d" \
      -mindepth 2 \
      -path '*/.terragrunt-cache/*' -prune -o \
      -name terragrunt.hcl -print -quit \
    | grep -q .; then
    continue
  fi

  STACK_DIRS+=("$d")
done

echo "Stacks leaf detectados: ${#STACK_DIRS[@]}"
printf '%s\n' "${STACK_DIRS[@]}" | sed 's/^/ - /'
echo

# 3) Effective backend per stack (SANITIZED; do not print inputs)
if command -v terragrunt >/dev/null 2>&1; then
  echo "Backend efectivo por stack (sanitizado desde terragrunt render --json):"

  if ! command -v python3 >/dev/null 2>&1; then
    echo "WARN: python3 no está disponible; se omite resumen sanitizado de remote_state."
    echo
  fi

  for sd in "${STACK_DIRS[@]}"; do
    echo
    echo "--- STACK: $sd"
    if [[ -f "$sd/state/terraform.tfstate" ]]; then
      echo "State local: PRESENT ($sd/state/terraform.tfstate)"
    else
      echo "State local: MISSING ($sd/state/terraform.tfstate)"
    fi

    if command -v python3 >/dev/null 2>&1; then
      (
        cd "$sd" || exit 0
        python3 -c '
import json
import sys

try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(0)

rs = data.get("remote_state") or {}
cfg = rs.get("config") or {}

backend = rs.get("backend")
if backend not in (None, ""):
    print(f"backend: {backend}")

for k in ("path", "bucket", "key", "dynamodb_table", "endpoint", "region"):
    v = cfg.get(k)
    if v not in (None, ""):
        print(f"{k}: {v}")
' < <(terragrunt render --json 2>/dev/null) || true
      ) || true
    fi
  done
  echo
else
  echo "WARN: terragrunt no está disponible en PATH; se omite render --json."
  echo
fi

# 4) Canonical states outside cache (expected: 1 per stack => */state/terraform.tfstate)
CANON_STATES="$(
  find live \
    -path '*/.terragrunt-cache/*' -prune -o \
    -type f -path '*/state/terraform.tfstate' -print | sort || true
)"
echo "States canónicos (fuera de cache) detectados:"
if [[ -n "${CANON_STATES}" ]]; then
  while IFS= read -r line; do
    printf ' - %s\n' "$line"
  done <<<"$CANON_STATES"
else
  echo " - (ninguno aún)"
fi
echo

# 5) FAIL: any tfstate outside state/ (outside cache)
NONCANON="$(
  find live \
    -path '*/.terragrunt-cache/*' -prune -o \
    -type f \( -name '*.tfstate' -o -name '*.tfstate.*' -o -name 'terraform.tfstate' -o -name 'terraform.tfstate.*' \) \
    ! -path '*/state/*' -print | sort || true
)"
if [[ -n "${NONCANON}" ]]; then
  echo "FAIL: tfstate encontrado fuera de state/ (fuera de cache):"
  while IFS= read -r line; do
    printf ' - %s\n' "$line"
  done <<<"$NONCANON"
  exit 2
fi

# 6) WARNING/STRICT: tfstate inside cache (possible leftovers/confusion)
CACHE_STATES="$(
  find live -type f -path '*/.terragrunt-cache/*terraform.tfstate*' -print | sort || true
)"
if [[ -n "${CACHE_STATES}" ]]; then
  echo "WARN: tfstate encontrado dentro de .terragrunt-cache (posibles residuos/confusión):"
  while IFS= read -r line; do
    printf ' - %s\n' "$line"
  done <<<"$CACHE_STATES"
  echo
  if [[ "${STRICT_CACHE:-0}" == "1" ]]; then
    echo "FAIL: STRICT_CACHE=1 está activo y se encontraron tfstates en cache."
    exit 3
  fi
fi

# 7) Informational locks
LOCKS="$(
  find live -type f \( -name '*.lock.info' -o -name '.terraform.tfstate.lock.info' \) -print | sort || true
)"
if [[ -n "${LOCKS}" ]]; then
  echo "INFO: locks detectados:"
  while IFS= read -r line; do
    printf ' - %s\n' "$line"
  done <<<"$LOCKS"
  echo
else
  echo "Locks: (ninguno detectado)"
  echo
fi

# 8) Backend configs (if present)
if [[ -d "$CONFIG_DIR" ]]; then
  echo "Backend configs (config/backend-*.hcl):"
  backend_files="$(find "$CONFIG_DIR" -maxdepth 1 -type f -name 'backend-*.hcl' -print | sort || true)"
  if [[ -n "$backend_files" ]]; then
    while IFS= read -r line; do
      printf ' - %s\n' "$line"
    done <<<"$backend_files"
  else
    echo " - (no hay backend-*.hcl)"
  fi
  echo
  echo "backend_enabled (si aplica):"
  grep -nE 'backend_enabled\s*=' "$CONFIG_DIR"/backend-*.hcl 2>/dev/null || echo " - (no encontrado)"
  echo
fi

echo "OK: No se encontraron tfstates fuera de state/ (excluyendo cache)."
exit 0
