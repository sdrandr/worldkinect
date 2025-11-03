#!/usr/bin/env bash
set -Eeuo pipefail
trap 'log "ERROR: Script failed on line $LINENO"; exit 1' ERR

# ------------------- Configuration -------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$SCRIPT_DIR"
mkdir -p "$LOG_DIR"

S3_BUCKET="kinect-terraform-state"
DDB_TABLE="kinect-terraform-locks"
KMS_ALIAS="alias/terraform"

PROFILE=""
LOG_FILE=""
DEBUG=${DEBUG:-0}

# ------------------- Logging -------------------
setup_log() {
  mkdir -p "$LOG_DIR"
  if command -v mktemp >/dev/null 2>&1; then
    # macOS vs GNU mktemp
    LOG_FILE=$(mktemp "$LOG_DIR/resource_status.XXXXXX.log" 2>/dev/null || echo "$LOG_DIR/resource_status.log")
  else
    LOG_FILE="$LOG_DIR/resource_status.log"
  fi
  : > "$LOG_FILE"  # truncate
}

log() {
  local msg="$*"
  printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$msg" | tee -a "$LOG_FILE" >&2
}

# ------------------- Parse Arguments -------------------
while [[ $# -gt 0 ]]; do
  case $1 in
    --profile) PROFILE="$2"; shift 2 ;;
    -h|--help)
      echo "Usage: $0 --profile <aws-profile>"
      exit 0 ;;
    *) echo "Error: Unknown argument $1" >&2; exit 1 ;;
  esac
done

if [[ -z "$PROFILE" ]]; then
  echo "Error: --profile is required" >&2
  exit 1
fi

setup_log
log "=== Precheck Started ==="
log "AWS Profile: $PROFILE"
log "Log File: $LOG_FILE"

# ------------------- Dependency Check -------------------
for bin in aws terraform; do
  if ! command -v "$bin" >/dev/null 2>&1; then
    log "ERROR: '$bin' not found in PATH"
    exit 1
  fi
done

(( DEBUG > 0 )) && set -x && log "DEBUG mode enabled"

# ------------------- Terraform Safe Import -------------------
safe_import() {
  local tf_resource="$1"
  local aws_id="$2"
  local description="$3"

  if terraform state list | grep -q "^${tf_resource}$"; then
    log "$description already managed by Terraform. Skipping import."
    return 0
  fi

  log "Importing $description ($tf_resource)..."
  if terraform import "$tf_resource" "$aws_id" 2>&1; then
    log "Successfully imported $tf_resource"
  else
    local code=$?
    log "ERROR: Failed to import $tf_resource (exit code: $code)"
    return $code
fi
}

# ------------------- S3 Bucket -------------------
S3_STATUS="NOT FOUND"
log "[s3api] Checking bucket: $S3_BUCKET"
if aws s3api head-bucket --bucket "$S3_BUCKET" --profile "$PROFILE" 2>/dev/null; then
  log "Resource exists. Preparing to import aws_s3_bucket.tf_state..."
  safe_import "aws_s3_bucket.tf_state" "$S3_BUCKET" "S3 bucket"
  if aws s3api get-bucket-versioning --bucket "$S3_BUCKET" --profile "$PROFILE" \
     | grep -q '"Status": "Enabled"'; then
    log "Versioning is enabled for $S3_BUCKET"
  else
    log "WARNING: Versioning not enabled for $S3_BUCKET"
  fi
  S3_STATUS="EXISTS"
fi

# ------------------- DynamoDB Table -------------------
DDB_STATUS="NOT FOUND"
log "[dynamodb] Checking table: $DDB_TABLE"
if aws dynamodb describe-table --table-name "$DDB_TABLE" --profile "$PROFILE" >/dev/null 2>&1; then
  log "Resource exists. Preparing to import aws_dynamodb_table.terraform_locks..."
  safe_import "aws_dynamodb_table.terraform_locks" "$DDB_TABLE" "DynamoDB table"
  DDB_STATUS="EXISTS"
fi

# ------------------- KMS Key / Alias -------------------
KMS_STATUS="NOT FOUND"
log "[kms] Checking alias: $KMS_ALIAS"

# Query for the TargetKeyId of the alias, safely handle errors and empty results
KMS_KEY_ID=$(aws kms list-aliases --profile "$PROFILE" \
  --query "Aliases[?AliasName == '${KMS_ALIAS}'].TargetKeyId | [0]" \
  --output text 2>/dev/null || echo "")

if [[ -n "$KMS_KEY_ID" && "$KMS_KEY_ID" != "None" ]]; then
  log "  Found existing KMS key for $KMS_ALIAS: $KMS_KEY_ID"
  safe_import "aws_kms_key.terraform_key" "$KMS_KEY_ID" "KMS key"
  safe_import "aws_kms_alias.terraform_alias" "$KMS_ALIAS" "KMS alias"
  KMS_STATUS="EXISTS"
else
  log "  KMS alias $KMS_ALIAS not found. Terraform will create key and alias."
fi

# ------------------- Summary Table -------------------
log ""
log "==================== Resource Summary ===================="
printf "%-20s | %-10s | %-30s\n" "RESOURCE" "STATUS" "DETAILS" | tee -a "$LOG_FILE"
printf '%.0s-' {1..65} | tee -a "$LOG_FILE"; echo | tee -a "$LOG_FILE"
printf "%-20s | %-10s | %-30s\n" "S3 Bucket" "$S3_STATUS" "$S3_BUCKET" | tee -a "$LOG_FILE"
printf "%-20s | %-10s | %-30s\n" "DynamoDB Table" "$DDB_STATUS" "$DDB_TABLE" | tee -a "$LOG_FILE"
printf "%-20s | %-10s | %-30s\n" "KMS Key" "$KMS_STATUS" "$KMS_ALIAS" | tee -a "$LOG_FILE"
log "==========================================================="
log "Precheck/import complete. See detailed log: $LOG_FILE"
