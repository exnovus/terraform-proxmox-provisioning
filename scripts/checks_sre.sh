#!/usr/bin/env bash
# Anti-regression checks: architecture rule (components only), formatting, gitignore, backend.
# --fast: only rg + formatting + gitignore; without the flag, includes scaffold + init + validate.
# rg exit 1 = no matches (treated as 0 findings); exit 2 = real error -> abort.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
# shellcheck source=scripts/lib_envcommon.sh
source "${SCRIPT_DIR}/lib_envcommon.sh"

cd "$REPO_ROOT"

MODE="full"
for arg in "$@"; do
  case "$arg" in
    --fast)  MODE="fast" ;;
    -h|--help)
      echo "Usage: $(basename "$0") [--fast]"
      echo "  --fast  Only run rg + gitignore checks (no scaffold/validate)"
      echo "  (default) Full suite: rg + gitignore + scaffold + terragrunt validate"
      exit 0
      ;;
  esac
done

PASS=0
FAIL=0
SKIP=0

check() {
  local label="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    echo "[PASS] ${label}"
    PASS=$((PASS + 1))
  else
    echo "[FAIL] ${label}"
    FAIL=$((FAIL + 1))
  fi
}

skip_check() {
  local label="$1"
  echo "[SKIP] ${label}"
  SKIP=$((SKIP + 1))
}

# ripgrep: 0 = matches found, 1 = no matches (expected in check_zero_hits), 2 = error (pattern/path).
# Abort only on 2 so "no results" is not confused with a tool failure.
_rg_count() {
  local rg_stderr rg_stdout rc
  rg_stderr="$(mktemp)"
  rg_stdout=$("$@" 2>"$rg_stderr") && rc=$? || rc=$?
  if [[ "$rc" -ge 2 ]]; then
    echo "[ERROR] rg failed (exit ${rc}): $*" >&2
    cat "$rg_stderr" >&2
    rm -f "$rg_stderr"
    exit 2
  fi
  rm -f "$rg_stderr"
  if [[ -z "$rg_stdout" ]]; then
    echo "0"
  else
    echo "$rg_stdout" | wc -l
  fi
}

check_zero_hits() {
  local label="$1"
  shift
  local hits
  hits=$(_rg_count "$@")
  if [[ "$hits" -eq 0 ]]; then
    echo "[PASS] ${label} (0 hits)"
    PASS=$((PASS + 1))
  else
    echo "[FAIL] ${label} (${hits} hits)"
    "$@" 2>/dev/null | head -5
    FAIL=$((FAIL + 1))
  fi
}

check_nonzero_hits() {
  local label="$1"
  shift
  local hits
  hits=$(_rg_count "$@")
  if [[ "$hits" -gt 0 ]]; then
    echo "[PASS] ${label} (${hits} hits)"
    PASS=$((PASS + 1))
  else
    echo "[FAIL] ${label} (0 hits — expected ≥1)"
    FAIL=$((FAIL + 1))
  fi
}

check_no_duplicated_proxmox_defaults() {
  local file_path="$1"
  shift
  local key

  for key in "$@"; do
    if rg -n "^${key}:" "$file_path" >/dev/null 2>&1 && rg -n "^  ${key}:" "$file_path" >/dev/null 2>&1; then
      echo "[ERROR] Duplicate key found at root and proxmox.${key}: ${file_path}" >&2
      return 1
    fi
  done
}

echo "=== SRE Checks — $(date -Iseconds) ==="
echo "Repo: ${REPO_ROOT}"
echo "Mode: ${MODE}"
echo

# Bootstrap envcommon from templates if live/_envcommon does not exist yet.
ensure_envcommon_dir "$REPO_ROOT" "false" >/dev/null
assert_envcommon_ready "$REPO_ROOT"

# Architecture rule and conventions: Terragrunt -> components; resources without module.terraform_tags.
echo "--- Anti-regression ---"
check_nonzero_hits "envcommon → components" \
  rg -n 'modules//components/' live/_envcommon/

check_zero_hits "No source → resources" \
  rg -n 'modules//resources/' live/ scripts/ --glob '!checks_sre.sh'

check_zero_hits "Workloads sin module.terraform_tags" \
  rg -n 'module\.terraform_tags' modules/resources/

check_nonzero_hits "Components con module.terraform_tags" \
  rg -n 'module\.terraform_tags' modules/components/

check_zero_hits "No generate tags" \
  rg -n 'generate\s+"tags"' live/

check_nonzero_hits "Script valida envcommon" \
  rg -n '_envcommon' scripts/create_environment_stack.sh

residual_pattern='gl'"obals\\.a"'uto\\.tfvars'
residual_pattern+='|default_stage'"_list"
residual_pattern+='|organi'"zation"
check_zero_hits "No repo global config drift" \
  rg -n "$residual_pattern" -S . --glob '!scripts/checks_sre.sh'

check_nonzero_hits "VM tags_list computed" \
  rg -n 'tags_list\s*=' modules/resources/proxmox-vm/main.tf

check_nonzero_hits "CT tags_list computed" \
  rg -n 'tags_list\s*=' modules/resources/proxmox-lxc/main.tf

check_nonzero_hits "VM provider receives tags_list" \
  rg -n 'tags\s*=\s*each\.value\.tags_list' modules/resources/proxmox-vm/main.tf

check_nonzero_hits "CT provider receives tags_list" \
  rg -n 'tags\s*=\s*each\.value\.tags_list' modules/resources/proxmox-lxc/main.tf

check_nonzero_hits "VM default_vm_id_base wired end-to-end" \
  rg -n 'default_vm_id_base' templates/envcommon/vm-service.hcl modules/components/vm-service/ modules/resources/proxmox-vm/

check_nonzero_hits "CT default_ct_template/default_os_template wired end-to-end" \
  rg -n 'default_ct_template|default_os_template' config/datacenter-defaults.yaml scripts/create_environment_datacenter.sh scripts/create_environment_stack.sh templates/envcommon/lxc-service.hcl modules/components/lxc-service/ modules/resources/proxmox-lxc/

check "No duplicated scaffold keys between root and proxmox" \
  check_no_duplicated_proxmox_defaults config/datacenter-defaults.yaml \
    default_node default_bridge default_storage default_pool \
    default_vm_template default_template_vm_id default_vm_id_base \
    default_ct_template default_ct_id_base

# ── Formatting ───────────────────────────────────────────────
echo
echo "--- Format ---"
check "terraform fmt (modules)" \
  terraform fmt -check -recursive modules/

# ── Gitignore ────────────────────────────────────────────────
echo
echo "--- Gitignore ---"
check "_envcommon files exist" \
  test -f live/_envcommon/vm-service.hcl -a -f live/_envcommon/lxc-service.hcl

check_zero_hits "No .tfstate tracked" \
  rg -l '\.tfstate' config/ modules/ scripts/ live/_envcommon/ --glob '!*.md' --glob '!*.sh' --glob '!*.hcl'

# ── Backend configs ──────────────────────────────────────────
echo
echo "--- Backend configs ---"
check "backend-dev.hcl exists" \
  test -f config/backend-dev.hcl

check_zero_hits "No credentials in config/" \
  rg -in 'password|secret_key|access_key' config/ --glob '!*.md'

# ── Fast mode ends here ──────────────────────────────────────
if [[ "$MODE" == "fast" ]]; then
  echo
  echo "=== Result (fast): ${PASS} passed, ${FAIL} failed, ${SKIP} skipped ==="
  [[ "$FAIL" -gt 0 ]] && exit 1
  exit 0
fi

# ── Scaffold + validate (fixture) ────────────────────────────
echo
echo "--- Scaffold + validate (fixture) ---"

FIXTURE_ENV="sre-check"
FIXTURE_DC="dc-fixture"
FIXTURE_STACK_VM="chk-vm"
FIXTURE_STACK_CT="chk-ct"

cleanup_fixture() {
  rm -rf "${REPO_ROOT}/live/${FIXTURE_ENV}" 2>/dev/null || true
}
trap cleanup_fixture EXIT

cleanup_fixture

./scripts/create_environment.sh "$FIXTURE_ENV" --force >/dev/null 2>&1
./scripts/create_environment_datacenter.sh "$FIXTURE_ENV" "$FIXTURE_DC" --force >/dev/null 2>&1
./scripts/create_environment_stack.sh "$FIXTURE_ENV" "$FIXTURE_DC" "$FIXTURE_STACK_VM" vm --force >/dev/null 2>&1
./scripts/create_environment_stack.sh "$FIXTURE_ENV" "$FIXTURE_DC" "$FIXTURE_STACK_CT" ct --force >/dev/null 2>&1

export PM_API_URL="${PM_API_URL:-https://pve.fixture.invalid:8006/api2/json}"
export PM_USER="${PM_USER:-fixture@pam}"
export PM_PASSWORD="${PM_PASSWORD:-}"
export PM_TLS_INSECURE="${PM_TLS_INSECURE:-true}"

vm_dir="${REPO_ROOT}/live/${FIXTURE_ENV}/${FIXTURE_DC}/${FIXTURE_STACK_VM}"
ct_dir="${REPO_ROOT}/live/${FIXTURE_ENV}/${FIXTURE_DC}/${FIXTURE_STACK_CT}"

echo "  Scaffolded fixture: ${FIXTURE_ENV}/${FIXTURE_DC}/{${FIXTURE_STACK_VM},${FIXTURE_STACK_CT}}"

vm_init_rc=0
(cd "$vm_dir" && echo "y" | terragrunt init >/dev/null 2>&1) || vm_init_rc=$?
check "VM init" test "$vm_init_rc" -eq 0

vm_val_rc=0
(cd "$vm_dir" && terragrunt validate >/dev/null 2>&1) || vm_val_rc=$?
check "VM validate" test "$vm_val_rc" -eq 0

ct_init_rc=0
(cd "$ct_dir" && echo "y" | terragrunt init >/dev/null 2>&1) || ct_init_rc=$?
check "CT init" test "$ct_init_rc" -eq 0

ct_val_rc=0
(cd "$ct_dir" && terragrunt validate >/dev/null 2>&1) || ct_val_rc=$?
check "CT validate" test "$ct_val_rc" -eq 0

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  if git check-ignore -q "live/${FIXTURE_ENV}/"; then
    echo "[PASS] Fixture ignored by gitignore"
    PASS=$((PASS + 1))
  else
    echo "[FAIL] Fixture ignored by gitignore"
    FAIL=$((FAIL + 1))
    exit 1
  fi

  fixture_tracked=$(git status --porcelain "live/${FIXTURE_ENV}/" 2>/dev/null | wc -l)
  check "Fixture not tracked by git (gitignore)" test "$fixture_tracked" -eq 0
else
  skip_check "Git fixture checks (not running inside a git worktree)"
fi

echo
echo "=== Result: ${PASS} passed, ${FAIL} failed, ${SKIP} skipped ==="

if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
