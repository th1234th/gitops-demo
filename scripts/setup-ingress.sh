#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INGRESS_FILE="$ROOT/k8s/app-ingress.yaml"
NAMESPACE="ci-cd"
INGRESS_NAME="ci-cd-app-ingress"
HOST="ci-cd.local"
APPLY_HOSTS=false

if [[ "${1:-}" == "--apply-hosts" ]]; then
  APPLY_HOSTS=true
fi

command -v kubectl >/dev/null 2>&1 || { echo "kubectl is required" >&2; exit 1; }

if [[ ! -f "$INGRESS_FILE" ]]; then
  echo "Ingress manifest not found: $INGRESS_FILE" >&2
  exit 1
fi

echo "[1/2] Applying ingress manifest: $INGRESS_FILE"
kubectl apply -f "$INGRESS_FILE"

echo "[2/2] Resolving host IP for $HOST"
IP=""
for i in {1..10}; do
  IP="$(kubectl get ingress "$INGRESS_NAME" -n "$NAMESPACE" -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || true)"
  if [[ -n "$IP" ]]; then
    break
  fi
  if command -v minikube >/dev/null 2>&1; then
    IP="$(minikube ip 2>/dev/null || true)"
    if [[ -n "$IP" ]]; then
      break
    fi
  fi
  sleep 2
 done

if [[ -z "$IP" ]]; then
  echo "Unable to resolve an ingress IP address for $INGRESS_NAME in namespace $NAMESPACE." >&2
  echo "Check ingress status with: kubectl get ingress $INGRESS_NAME -n $NAMESPACE" >&2
  exit 1
fi

echo
if [[ "$APPLY_HOSTS" == true ]]; then
  if [[ "$EUID" -ne 0 ]]; then
    echo "Re-run with sudo to update /etc/hosts, or run without --apply-hosts to print the mapping." >&2
    exit 1
  fi
  if ! grep -qF "$HOST" /etc/hosts; then
    echo "$IP $HOST" >> /etc/hosts
    echo "Updated /etc/hosts with: $IP $HOST"
  else
    echo "/etc/hosts already contains an entry for $HOST"
  fi
else
  echo "Add this host mapping to /etc/hosts:" 
  echo "  $IP $HOST"
  echo "To update /etc/hosts automatically, run this script with --apply-hosts."
fi
