#!/usr/bin/env bash
set -euo pipefail

# =============================================================
# Terraform Environment Deployment Script
# Author: DB Automation Team
# Purpose: Safe and logged Terraform deploy for any environment
# Usage: ./scripts/deploy.sh <environment> [plan|apply]
# =============================================================

# --- CONFIG ---
ENV=${1:-}
ACTION=${2:-apply}
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_DIR="$ROOT_DIR/terraform/environments/$ENV"
BACKEND_FILE="$ENV_DIR/backend.$ENV.tfvars"
COMMON_BACKEND="$ROOT_DIR/terraform/common/backend.tfvars"
LOG_DIR="$ROOT_DIR/logs"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="$LOG_DIR/deploy-${ENV}-${TIMESTAMP}.log"

# --- FUNCTIONS ---
log() {
  local level="$1"; shift
  local message="$*"
  local color_reset="\033[0m"
  local color_info="\033[1;34m"
  local color_warn="\033[1;33m"
  local color_error="\033[1;31m"
  local color_success="\033[1;32m"

  case "$level" in
    INFO)    echo -e "${color_info}[$(date +'%Y-%m-%d %H:%M:%S')] [INFO]${color_reset} $message" | tee -a "$LOG_FILE" ;;
    WARN)    echo -e "${color_warn}[$(date +'%Y-%m-%d %H:%M:%S')] [WARN]${color_reset} $message" | tee -a "$LOG_FILE" ;;
    ERROR)   echo -e "${color_error}[$(date +'%Y-%m-%d %H:%M:%S')] [ERROR]${color_reset} $message" | tee -a "$LOG_FILE" ;;
    SUCCESS) echo -e "${color_success}[$(date +'%Y-%m-%d %H:%M:%S')] [OK]${color_reset} $message" | tee -a "$LOG_FILE" ;;
    *)       echo "[$(date +'%Y-%m-%d %H:%M:%S')] $message" | tee -a "$LOG_FILE" ;;
  esac
}

cleanup() {
  log WARN "Deployment interrupted or failed. Review log file: $LOG_FILE"
}
trap cleanup ERR SIGINT SIGTERM

# --- PRE-FLIGHT VALIDATION ---
if [[ -z "$ENV" ]]; then
  echo "Usage: $0 <environment> [plan|apply]"
  exit 1
fi

mkdir -p "$LOG_DIR"

if [[ ! -d "$ENV_DIR" ]]; then
  log ERROR "Environment directory not found: $ENV_DIR"
  exit 1
fi

log INFO "==== Terraform Deployment Started ===="
log INFO "Environment : $ENV"
log INFO "Action      : $ACTION"
log INFO "Log file    : $LOG_FILE"
log INFO "Timestamp   : $TIMESTAMP"
log INFO "---------------------------------------"

cd "$ENV_DIR"

# --- INIT ---
if [[ -f "$BACKEND_FILE" ]]; then
  log INFO "Initializing backend from $BACKEND_FILE"
  terraform init -backend-config="$BACKEND_FILE" 2>&1 | tee -a "$LOG_FILE"
else
  log WARN "No environment-specific backend found; using common backend"
  terraform init -backend-config="$COMMON_BACKEND" 2>&1 | tee -a "$LOG_FILE"
fi

# --- FORMAT & VALIDATE ---
log INFO "Running terraform fmt and validate..."
terraform fmt -recursive | tee -a "$LOG_FILE"
terraform validate | tee -a "$LOG_FILE"

# --- PLAN / APPLY ---
if [[ "$ACTION" == "plan" ]]; then
  log INFO "Creating Terraform plan..."
  terraform plan -var-file=terraform.tfvars -out=tfplan 2>&1 | tee -a "$LOG_FILE"
  log SUCCESS "Plan completed successfully."
elif [[ "$ACTION" == "apply" ]]; then
  log INFO "Planning and applying Terraform changes..."
  terraform plan -var-file=terraform.tfvars -out=tfplan 2>&1 | tee -a "$LOG_FILE"
  terraform apply -auto-approve tfplan 2>&1 | tee -a "$LOG_FILE"
  log SUCCESS "Apply completed successfully."
else
  log ERROR "Unknown action '$ACTION' — use 'plan' or 'apply'."
  exit 1
fi

log SUCCESS "✅ Deployment complete for $ENV"
log INFO "Log file stored at: $LOG_FILE"
