#!/usr/bin/env bash
set -euo pipefail

# ==========================================
# update-iam-policy.sh
# Safely updates an existing IAM policy using a direct ARN.
# Eliminates the need for iam:ListPolicies.
# Supports --profile, --policy-arn, and --policy-path flags.
# ==========================================

# --- Default values ---
AWS_PROFILE="terraform-admin"
POLICY_ARN=""  # Must be provided
POLICY_PATH="environments/common/policies/iam-policy.json"

# --- Helper function for errors ---
error_exit() {
  echo "❌ ERROR: $1" >&2
  exit 1
}

# --- Help message ---
usage() {
  cat <<EOF
Usage: $0 [options]

Options:
  -p, --profile <name>     AWS profile name (default: terraform-admin)
  -a, --policy-arn <arn>   IAM policy ARN (required)
  -f, --policy-path <path> Path to IAM policy JSON (default: environments/common/policies/iam-policy.json)
  -h, --help               Show this help message
EOF
  exit 0
}

# --- Parse flags ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    -p|--profile)
      AWS_PROFILE="$2"
      shift 2
      ;;
    -a|--policy-arn)
      POLICY_ARN="$2"
      shift 2
      ;;
    -f|--policy-path)
      POLICY_PATH="$2"
      shift 2
      ;;
    -h|--help)
      usage
      ;;
    *)
      echo "Unknown option: $1"
      usage
      ;;
  esac
done

# --- Validate inputs ---
if [ -z "$POLICY_ARN" ]; then
  error_exit "Policy ARN must be provided with --policy-arn"
fi

if [ ! -f "$POLICY_PATH" ]; then
  error_exit "Policy file not found at: $POLICY_PATH"
fi

echo "🧭 Using AWS profile: $AWS_PROFILE"
echo "📄 Policy file: $POLICY_PATH"
echo "🔖 Policy ARN: $POLICY_ARN"

# --- Verify credentials ---
ACCOUNT_ID=$(aws sts get-caller-identity --profile "$AWS_PROFILE" --query 'Account' --output text 2>/dev/null || true)
if [ -z "$ACCOUNT_ID" ]; then
  error_exit "Failed to verify AWS credentials for profile '$AWS_PROFILE'."
fi
echo "✅ Connected to AWS Account: $ACCOUNT_ID"

# --- Create new policy version ---
echo "🚀 Creating new IAM policy version..."
aws iam create-policy-version \
  --profile "$AWS_PROFILE" \
  --policy-arn "$POLICY_ARN" \
  --policy-document "file://$POLICY_PATH" \
  --set-as-default \
  --no-cli-pager || error_exit "Failed to create policy version."

echo "✅ Successfully created new policy version and set it as default."

# --- Clean up older versions (IAM allows max 5) ---
OLD_VERSIONS=$(aws iam list-policy-versions \
  --profile "$AWS_PROFILE" \
  --policy-arn "$POLICY_ARN" \
  --query "Versions[?IsDefaultVersion==\`false\`].VersionId" --output text)

if [ -n "$OLD_VERSIONS" ]; then
  echo "🧹 Cleaning up old policy versions..."
  for version in $OLD_VERSIONS; do
    echo "   - Deleting old version: $version"
    aws iam delete-policy-version \
      --profile "$AWS_PROFILE" \
      --policy-arn "$POLICY_ARN" \
      --version-id "$version" \
      --no-cli-pager || true
  done
fi

echo "🎉 IAM policy successfully updated and cleaned up."
