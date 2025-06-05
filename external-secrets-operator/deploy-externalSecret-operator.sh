#!/bin/bash

set -euo pipefail

# Available providers
VALID_PROVIDERS=("bitwarden")

# Default provider variable
PROVIDER=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --provider)
      PROVIDER="$2"
      shift 2
      ;;
    *)
      echo "❌ Unknown argument: $1"
      echo "Usage: $0 --provider <${VALID_PROVIDERS[*]}>"
      exit 1
      ;;
  esac
done

# Validate provider
if [[ -z "$PROVIDER" ]]; then
  echo "❌ No provider specified. Use --provider option."
  echo "Example: $0 --provider bitwarden"
  exit 1
fi

if [[ ! " ${VALID_PROVIDERS[*]} " =~ " ${PROVIDER} " ]]; then
  echo "❌ Invalid provider: $PROVIDER"
  echo "Supported providers: ${VALID_PROVIDERS[*]}"
  exit 1
fi

echo "📦 Adding External Secrets Helm repository..."
helm repo add external-secrets https://charts.external-secrets.io
helm repo update

PROVIDER_SCRIPT="./providers/${PROVIDER}-config.sh"

if [[ ! -f "$PROVIDER_SCRIPT" ]]; then
  echo "❌ Provider script not found: $PROVIDER_SCRIPT"
  exit 1
fi

echo "⚙️  Sourcing provider config: $PROVIDER"
source "$PROVIDER_SCRIPT"

echo "✅ Setup complete for provider: $PROVIDER"
