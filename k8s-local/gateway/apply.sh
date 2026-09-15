#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

kubectl apply -f "${SCRIPT_DIR}/00-namespace.yaml"
kubectl create configmap kong-config \
  --namespace gateway \
  --from-file=kong.yaml="${SCRIPT_DIR}/kong.yaml" \
  --dry-run=client \
  --output yaml | kubectl apply -f -
kubectl apply -f "${SCRIPT_DIR}/01-kong.yaml"
kubectl rollout status deployment/kong -n gateway --timeout=180s
