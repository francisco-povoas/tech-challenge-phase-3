#!/usr/bin/env bash
set -euo pipefail

: "${GRAFANA_ADMIN_PASSWORD:?Defina GRAFANA_ADMIN_PASSWORD antes do deploy.}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NAMESPACE="observability"

apply_configmap() {
  local name="$1"
  local key="$2"
  local file="$3"

  kubectl create configmap "$name" \
    --namespace "$NAMESPACE" \
    --from-file="${key}=${file}" \
    --dry-run=client \
    --output yaml | kubectl apply -f -
}

kubectl apply -f "${SCRIPT_DIR}/00-namespace.yaml"

apply_configmap otel-collector-config config.yaml "${SCRIPT_DIR}/otel-collector-config.yaml"
apply_configmap prometheus-config prometheus.yml "${SCRIPT_DIR}/prometheus-config.yaml"
apply_configmap grafana-datasource prometheus.yaml "${SCRIPT_DIR}/grafana-datasource.yaml"

kubectl create secret generic grafana-admin-credentials \
  --namespace "$NAMESPACE" \
  --from-literal=username=admin \
  --from-literal=password="$GRAFANA_ADMIN_PASSWORD" \
  --dry-run=client \
  --output yaml | kubectl apply -f -

kubectl apply -f "${SCRIPT_DIR}/01-jaeger.yaml"
kubectl apply -f "${SCRIPT_DIR}/02-otel-collector.yaml"
kubectl apply -f "${SCRIPT_DIR}/03-prometheus.yaml"
kubectl apply -f "${SCRIPT_DIR}/04-grafana.yaml"

for deployment in jaeger otel-collector prometheus grafana; do
  kubectl rollout status "deployment/${deployment}" -n "$NAMESPACE" --timeout=180s
done
