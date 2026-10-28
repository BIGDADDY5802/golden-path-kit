#!/usr/bin/env bash
# Destroys the environments/* demo infrastructure (VPC, security groups, the workload-dev
# IAM role and S3 bucket) so no cost accrues between working sessions.
#
# Deliberately does NOT touch bootstrap/ (the AWS Organization member accounts, the
# remote-state backends, the OIDC provider reference, the ci-deploy roles, or the SNS
# drift-alert topic) - that's the persistent platform layer this project's CI/CD and
# drift detection depend on, and it costs ~$0 at this usage level, so there's no reason
# to tear it down between sessions.
#
# Usage:
#   scripts/teardown.sh          interactive - shows the destroy plan, asks before each environment
#   scripts/teardown.sh --yes    non-interactive - destroys both without prompting

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Reverse of apply order: workload-dev reads shared-network's state via a cross-account
# remote-state lookup, so shared-network must still exist while workload-dev is destroyed.
ENVIRONMENTS=("workload-dev" "shared-network")

AUTO_APPROVE=false
if [[ "${1:-}" == "--yes" ]]; then
  AUTO_APPROVE=true
elif [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  grep '^#' "$0" | sed 's/^# \{0,1\}//'
  exit 0
fi

echo "golden-path-kit teardown"
echo "Target: ${ENVIRONMENTS[*]} (in that order)"
echo "Not touched: bootstrap/ (accounts, state backends, OIDC/ci-deploy roles, SNS topic)"
echo ""

for env in "${ENVIRONMENTS[@]}"; do
  dir="$REPO_ROOT/environments/$env"

  if [[ ! -d "$dir" ]]; then
    echo "Skipping $env: $dir not found."
    continue
  fi

  echo "=== $env ==="
  (cd "$dir" && terraform init -input=false -no-color >/dev/null)

  echo "--- terraform plan -destroy ($env) ---"
  (cd "$dir" && terraform plan -destroy -input=false -no-color)

  if [[ "$AUTO_APPROVE" != true ]]; then
    read -r -p "Destroy $env now? [y/N] " answer
    if [[ ! "$answer" =~ ^[Yy]$ ]]; then
      echo "Skipped $env."
      echo ""
      continue
    fi
  fi

  (cd "$dir" && terraform destroy -auto-approve -input=false -no-color)
  echo "$env destroyed."
  echo ""
done

echo "Teardown complete."
