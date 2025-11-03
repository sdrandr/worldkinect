#!/usr/bin/env bash
# bootstrap/add-temp-terraform-permissions.sh
# Adds temporary inline IAM policy to terraform-admin for bootstrapping
# Safe, idempotent, robust logging, macOS-compatible

set -euo pipefail

# ------------------- Configuration -------------------
USER_NAME="terraform-admin"
POLICY_NAME="TerraformBootstrapTempAccess"
DEBUG=${DEBUG:-0}

# Resolve script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
POLICY_FILE="${SCRIPT_DIR}/${POLICY_NAME}.json"

# ------------------- Argument Parsing -------------------
ADMIN_PROFILE=""
TARGET_USER=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --admin-profile)
      ADMIN_PROFILE="$2"
      shift 2
      ;;
    --target-profile)
      TARGET_USER="$2"
      shift 2
      ;;
    -h|--help)
      cat <<EOF
Usage: $0 --admin-profile <admin-profile> [--target-profile <target-user>]

  --admin-profile   AWS profile with IAM admin rights (required)
  --target-profile  IAM user to modify (default: terraform-admin)
EOF
      exit 0
      ;;
    *)
      echo "Error: Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

if [[ -z "$ADMIN_PROFILE" ]]; then
  echo "Error: --admin-profile is required" >&2
  exit 1
fi

# Use target user if provided, else default
USER_NAME="${TARGET_USER:-$USER_NAME}"

# ------------------- Logging Setup (macOS-safe) -------------------
LOG_DIR="$SCRIPT_DIR"
mkdir -p "$LOG_DIR"

setup_log() {
  if command -v mktemp >/dev/null 2>&1; then
    if mktemp --help 2>&1 | grep -q -- '--tmpdir'; then
      LOG_FILE=$(mktemp --tmpdir="$LOG_DIR" add_temp_perms.XXXXXX.log 2>/dev/null || true)
    fi
    if [[ -z "${LOG_FILE:-}" ]]; then
      LOG_FILE=$(mktemp "$LOG_DIR/add_temp_perms.XXXXXX.log" 2>/dev/null || true)
    fi
  fi

  # Final fallback: unique timestamp + PID
  if [[ -z "${LOG_FILE:-}" || ! -w "${LOG_FILE:-}" ]]; then
    local ts=$(date '+%Y%m%d%H%M%S')
    local pid=$$
    LOG_FILE="${LOG_DIR}/add_temp_perms.${ts}.${pid}.log"
  fi

  : > "$LOG_FILE"
}

setup_log

log() {
  printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" | tee -a "$LOG_FILE" >&2
}

log "Starting temporary permission bootstrap"
log "Admin profile: $ADMIN_PROFILE"
log "Target user: $USER_NAME"
log "Policy name: $POLICY_NAME"
log "Policy file: $POLICY_FILE"
log "Log file: $LOG_FILE"

(( DEBUG > 0 )) && set -x && log "DEBUG mode enabled"

# ------------------- Write Policy JSON (CORRECTED HEREDOC) -------------------
log "Writing policy to $POLICY_FILE"

# Use quoted heredoc to prevent expansion, and NO || { } before JSON
cat > "$POLICY_FILE" <<'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "BootstrapPermissions",
      "Effect": "Allow",
      "Action": [
        "iam:CreatePolicy",
        "iam:CreatePolicyVersion",
        "iam:DeletePolicyVersion",
        "iam:ListPolicies",
        "iam:GetPolicy",
        "iam:GetPolicyVersion",
        "iam:AttachUserPolicy",
        "dynamodb:CreateTable",
        "dynamodb:DescribeTable",
        "dynamodb:PutItem",
        "dynamodb:GetItem",
        "dynamodb:DeleteItem",
        "dynamodb:DescribeContinuousBackups",
        "dynamodb:DescribeTimeToLive",
        "dynamodb:ListTagsOfResource",
        "dynamodb:DeleteTable",
        "dynamodb:UpdateTimeToLive",
        "dynamodb:TagResource",
        "kms:CreateKey",
        "kms:DescribeKey",
        "kms:GetKeyRotationStatus",
        "kms:ListKeys",
        "kms:CreateAlias",
        "kms:ListAliases",
        "kms:UpdateAlias",
        "kms:ListResourceTags",
        "kms:EnableKeyRotation",
        "kms:TagResource"
      ],
      "Resource": "*"
    }
  ]
}
EOF

# Only fail if file wasn't created
if [[ ! -f "$POLICY_FILE" ]] || ! grep -q "BootstrapPermissions" "$POLICY_FILE" 2>/dev/null; then
  log "ERROR: Failed to write valid policy file: $POLICY_FILE"
  exit 1
fi

log "Policy JSON written successfully"

# ------------------- Check & Attach Policy -------------------
log "Checking if inline policy '$POLICY_NAME' already exists on user '$USER_NAME'..."

if aws iam list-user-policies \
    --user-name "$USER_NAME" \
    --profile "$ADMIN_PROFILE" \
    --query "PolicyNames[?@=='$POLICY_NAME']" \
    --output text 2>/dev/null | grep -q .; then

  log "Policy '$POLICY_NAME' already attached. Skipping creation."

else
  log "Attaching inline policy '$POLICY_NAME' to user '$USER_NAME'..."

  if aws iam put-user-policy \
      --user-name "$USER_NAME" \
      --policy-name "$POLICY_NAME" \
      --policy-document "file://$POLICY_FILE" \
      --profile "$ADMIN_PROFILE" >>"$LOG_FILE" 2>&1; then
    log "Successfully attached temporary policy"
  else
    log "ERROR: Failed to attach policy. See log: $LOG_FILE"
    exit 1
  fi
fi

# ------------------- Final Output -------------------
log "Operation completed successfully"
log "Remove policy later with:"
log "  aws iam delete-user-policy --user-name $USER_NAME --policy-name $POLICY_NAME --profile $ADMIN_PROFILE"

cat <<EOF

Temporary permissions added to '$USER_NAME'!
Log: $LOG_FILE

Remember to delete the policy when done:
  aws iam delete-user-policy \\
    --user-name $USER_NAME \\
    --policy-name $POLICY_NAME \\
    --profile $ADMIN_PROFILE