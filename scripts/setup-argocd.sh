#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NAMESPACE_FILE="$ROOT/k8s/namespace.yaml"
ARGOCD_NAMESPACE="argocd"
ARGOCD_INSTALL_URL="https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml"
IMAGE_UPDATER_INSTALL_URL="https://raw.githubusercontent.com/argoproj-labs/argocd-image-updater/stable/manifests/install.yaml"
ARGOCD_APP_MANIFEST="$ROOT/k8s/argocd-app.yaml"
IMAGE_UPDATER_CONFIG="$ROOT/k8s/argocd-image-updater.yaml"
SKIP_IMAGE_UPDATER=false

if [[ "${1:-}" == "--skip-image-updater" ]]; then
  SKIP_IMAGE_UPDATER=true
fi

command -v kubectl >/dev/null 2>&1 || { echo "kubectl is required" >&2; exit 1; }
command -v curl >/dev/null 2>&1 || command -v wget >/dev/null 2>&1 || { echo "curl or wget is required" >&2; exit 1; }

if [[ ! -f "$NAMESPACE_FILE" ]]; then
  echo "Namespace manifest not found: $NAMESPACE_FILE" >&2
  exit 1
fi

if [[ ! -f "$ARGOCD_APP_MANIFEST" ]]; then
  echo "Argo CD app manifest not found: $ARGOCD_APP_MANIFEST" >&2
  exit 1
fi

if [[ ! -f "$IMAGE_UPDATER_CONFIG" ]]; then
  echo "Argo CD image updater config not found: $IMAGE_UPDATER_CONFIG" >&2
  exit 1
fi

apply_url() {
  local url="$1"
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$url"
  else
    wget -qO- "$url"
  fi
}

echo "[1/5] Creating namespaces"
kubectl apply -f "$NAMESPACE_FILE"

echo "[2/5] Installing Argo CD"
apply_url "$ARGOCD_INSTALL_URL" | kubectl apply --server-side -n "$ARGOCD_NAMESPACE" -f -

if [[ "$SKIP_IMAGE_UPDATER" == false ]]; then
  echo "[3/5] Installing Argo CD Image Updater"
  apply_url "$IMAGE_UPDATER_INSTALL_URL" | kubectl apply --server-side -n "$ARGOCD_NAMESPACE" -f -
else
  echo "[3/5] Skipping Argo CD Image Updater installation"
fi

echo "[4/5] Waiting for argocd-server service"
for i in {1..30}; do
  if kubectl -n "$ARGOCD_NAMESPACE" get svc argocd-server >/dev/null 2>&1; then
    break
  fi
  sleep 5
  echo "  waiting for argocd-server service... ($i/30)"
done

if ! kubectl -n "$ARGOCD_NAMESPACE" get svc argocd-server >/dev/null 2>&1; then
  echo "argocd-server service not found after waiting" >&2
  exit 1
fi

kubectl -n "$ARGOCD_NAMESPACE" get svc argocd-server

echo "[5/5] Applying local Argo CD manifests"
kubectl apply -f "$ARGOCD_APP_MANIFEST"
kubectl apply -f "$IMAGE_UPDATER_CONFIG"

echo
cat <<EOF
Argo CD bootstrap complete.

To access the Argo CD UI:
  kubectl port-forward svc/argocd-server -n argocd 8080:443
Then open:
  https://localhost:8080

Admin password:
  kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 --decode
EOF
