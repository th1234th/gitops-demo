#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="argocd"
SERVICE="argocd-server"
LOCAL_PORT="8080"
REMOTE_PORT="443"

command -v kubectl >/dev/null 2>&1 || { echo "kubectl is required" >&2; exit 1; }

if ! kubectl -n "$NAMESPACE" get svc "$SERVICE" >/dev/null 2>&1; then
  echo "Service '$SERVICE' not found in namespace '$NAMESPACE'." >&2
  echo "Make sure Argo CD is installed and the namespace exists." >&2
  exit 1
fi

echo "Forwarding local port $LOCAL_PORT to $SERVICE:$REMOTE_PORT in namespace $NAMESPACE"
echo "Press Ctrl+C to stop the port-forward and exit."

kubectl port-forward svc/$SERVICE -n "$NAMESPACE" "$LOCAL_PORT:$REMOTE_PORT"
