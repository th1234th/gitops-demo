#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CERT_NAME="ci-cd.local"
NAMESPACE="ci-cd"
SECRET_NAME="ci-cd-tls"
KEY_FILE="${ROOT}/${CERT_NAME}.key"
CRT_FILE="${ROOT}/${CERT_NAME}.crt"
NAMESPACE_FILE="${ROOT}/k8s/namespace.yaml"

command -v kubectl >/dev/null 2>&1 || { echo "kubectl is required" >&2; exit 1; }
command -v openssl >/dev/null 2>&1 || { echo "openssl is required" >&2; exit 1; }

echo "[1/4] Creating namespaces from ${NAMESPACE_FILE}"
kubectl apply -f "${NAMESPACE_FILE}"

echo "[2/4] Generating self-signed certificate for ${CERT_NAME}"
if [[ -f "${KEY_FILE}" && -f "${CRT_FILE}" ]]; then
  echo "  Existing certificate found, skipping generation"
else
  openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout "${KEY_FILE}" -out "${CRT_FILE}" \
    -subj "/CN=${CERT_NAME}/O=${CERT_NAME}"
fi

echo "[3/4] Creating or updating TLS secret ${SECRET_NAME} in namespace ${NAMESPACE}"
kubectl create secret tls "${SECRET_NAME}" --cert="${CRT_FILE}" --key="${KEY_FILE}" -n "${NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -

echo "[4/4] Setup complete"

echo "Generated certificate files:"
echo "  ${KEY_FILE}"
echo "  ${CRT_FILE}"

echo "Use the following host mapping to access https://${CERT_NAME}:"
if minikube ip >/dev/null 2>&1; then
  IP="$(minikube ip)"
  echo "  sudo sh -c 'echo \"${IP} ${CERT_NAME}\" >> /etc/hosts'"
else
  echo "  (unable to detect Minikube IP; add ${CERT_NAME} to your /etc/hosts or DNS manually)"
fi
