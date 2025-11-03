#!/usr/bin/env bash
# bootstrap/bootstrap-full.sh
# Full automated bootstrap – macOS & Linux compatible
# Fixes: mktemp race, function ordering, cleanup trap

set -Eeuo pipefail

# -------------------------------------------------------------------------
# EARLY SETUP: Define everything needed before strict mode bites
# -------------------------------------------------------------------------

# --- Config ---
ADMIN_PROFILE="${ADMIN_PROFILE:-}"
TARGET_USER="${TARGET_USER:-terraform-admin}"
BOOTSTRAP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEBUG="${DEBUG:-0}"

ADD_PERMS_SCRIPT="${BOOTSTRAP_DIR}/add-temp-terraform-permissions.sh"
PRECHECK_SCRIPT="${BOOTSTRAP_DIR}/precheck-aws-resources-import.sh"
TF_DIR="${BOOTSTRAP_DIR}"

LOG_DIR="${BOOTSTRAP_DIR}"
OUTPUT_LOG=""  # Will be set in setup_log()

# --- Log function (safe even if OUTPUT_LOG is empty) ---
log() {
  local msg="$*"
  printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$msg" >&2
  [[ -n "${OUTPUT_LOG}" && -f "${OUTPUT_LOG}" ]] && printf '%s\n' "$msg" >> "${OUTPUT_LOG}"
}

# --- Safe mktemp fallback (macOS-proof) ---
setup_log() {
  mkdir -p "${LOG_DIR}"

  if command -v mktemp >/dev/null 2>&1; then
    # Try GNU style first
    if mktemp --help 2>&1 | grep -q -- '--tmpdir'; then
      OUTPUT_LOG=$(mktemp --tmpdir="${LOG_DIR}" bootstrap-full.XXXXXX.log 2>/dev/null || true)
    fi
    # Try BSD/macOS style
    if [[ -z "${OUTPUT_LOG}" ]]; then
      OUTPUT_LOG=$(mktemp "${LOG_DIR}/bootstrap-full.XXXXXX.log" 2>/dev/null || true)
    fi
  fi

  # --- FINAL FALLBACK: unique name with timestamp + PID ---
  if [[ -z "${OUTPUT_LOG}" || ! -w "${OUTPUT_LOG}" ]]; then
    local timestamp
    timestamp=$(date '+%Y%m%d%H%M%S')
    local pid=$$
    local counter=0
    while :; do
      OUTPUT_LOG="${LOG_DIR}/bootstrap-full.${timestamp}.${pid}.${counter}.log"
      if [[ ! -e "${OUTPUT_LOG}" ]]; then
        : > "${OUTPUT_LOG}" && break
      fi
      ((counter++))
      [[ $counter -gt 100 ]] && log "ERROR: Could not create log file after 100 tries" && exit 1
    done
  fi

  # Truncate just in case
  : > "${OUTPUT_LOG}"
}

# --- Run early setup ---
setup_log
log "=== BOOTSTRAP START ==="
log "Log file: ${OUTPUT_LOG}"

# Enable debug *after* log is ready
(( DEBUG > 0 )) && set -x && log "DEBUG mode enabled"

# --- Dependency check ---
for cmd in aws terraform; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    log "ERROR: '$cmd' not found in PATH"
    exit 1
  fi
done

# --- Argument parsing ---
while [[ $# -gt 0 ]]; do
  case $1 in
    --admin-profile) ADMIN_PROFILE="$2"; shift 2 ;;
    --target-user)   TARGET_USER="$2";   shift 2 ;;
    -h|--help)
      cat <<EOF
Usage: $0 --admin-profile <admin> [--target-user <user>]

  --admin-profile   AWS profile with IAM admin rights (required)
  --target-user     IAM user to bootstrap (default: terraform-admin)
  --debug           Enable debug (or DEBUG=1)
EOF
      exit 0
      ;;
    *) log "ERROR: Unknown argument: $1"; exit 1 ;;
  esac
done

[[ -z "${ADMIN_PROFILE}" ]] && log "ERROR: --admin-profile required" && exit 1

log "Admin profile : ${ADMIN_PROFILE}"
log "Target user   : ${TARGET_USER}"
log "Directory     : ${BOOTSTRAP_DIR}"

# -------------------------------------------------------------------------
# DEFINE cleanup() BEFORE ANY trap
# -------------------------------------------------------------------------
cleanup() {
  local rc=$?
  [[ -n "${IN_TF_DIR:-}" ]] && popd >/dev/null 2>&1 || true
  if (( rc != 0 )); then
    log "ERROR: Bootstrap failed (exit $rc)"
  else
    log "Bootstrap completed successfully"
  fi
  log "Full log: ${OUTPUT_LOG}"
}
trap cleanup EXIT
trap 'log "ERROR: Failed on line $LINENO"; exit 1' ERR

# -------------------------------------------------------------------------
# Step 1: Grant temp permissions
# -------------------------------------------------------------------------
log "Step 1: Granting temp permissions to ${TARGET_USER}"
if ! bash "${ADD_PERMS_SCRIPT}" \
        --admin-profile "${ADMIN_PROFILE}" \
        --target-profile "${TARGET_USER}"; then
  log "ERROR: Permission script failed"
  exit 1
fi

# -------------------------------------------------------------------------
# Step 2: Precheck & import
# -------------------------------------------------------------------------
log "Step 2: Running precheck/import"
if ! bash "${PRECHECK_SCRIPT}" --profile "${TARGET_USER}"; then
  log "ERROR: Precheck script failed"
  exit 1
fi

# -------------------------------------------------------------------------
# Step 3: Terraform
# -------------------------------------------------------------------------
log "Step 3: Running Terraform in ${TF_DIR}"

if [[ ! -f "${TF_DIR}/main.tf" && ! -f "${TF_DIR}/versions.tf" ]]; then
  log "ERROR: No Terraform config in ${TF_DIR}"
  exit 1
fi

pushd "${TF_DIR}" >/dev/null
IN_TF_DIR=1

log "terraform init --reconfigure"
if ! terraform init --reconfigure >>"${OUTPUT_LOG}" 2>&1; then
  log "ERROR: terraform init failed"
  exit 1
fi

log "terraform apply -auto-approve"
if ! terraform apply -auto-approve >>"${OUTPUT_LOG}" 2>&1; then
  log "ERROR: terraform apply failed"
  exit 1
fi

popd >/dev/null
unset IN_TF_DIR

# -------------------------------------------------------------------------
# Step 4: Remove temp policy
# -------------------------------------------------------------------------
log "Step 4: Removing temp policy"
if aws iam delete-user-policy \
       --user-name "${TARGET_USER}" \
       --policy-name TerraformBootstrapTempAccess \
       --profile "${ADMIN_PROFILE}" >>"${OUTPUT_LOG}" 2>&1; then
  log "Temp policy removed"
else
  log "WARNING: Failed to remove temp policy. Run manually:"
  log "  aws iam delete-user-policy --user-name ${TARGET_USER} --policy-name TerraformBootstrapTempAccess --profile ${ADMIN_PROFILE}"
fi

# -------------------------------------------------------------------------
# Final success message
# -------------------------------------------------------------------------
log "=== BOOTSTRAP COMPLETE ==="

cat <<EOF

SUCCESS! Bootstrap finished.

Log: ${OUTPUT_LOG}

Next:
1. Check AWS Console
2. Commit .tfstate if using remote backend
3. (If needed) Clean up temp policy:
   aws iam delete-user-policy \\
     --user-name ${TARGET_USER} \\
     --policy-name TerraformBootstrapTempAccess \\
     --profile ${ADMIN_PROFILE}

EOF