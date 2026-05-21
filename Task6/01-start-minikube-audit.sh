#!/bin/bash
set -euo pipefail

PROFILE="${PROFILE:-task6-audit}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AUDIT_DIR="${SCRIPT_DIR}/minikube-audit"
NODE_POLICY_PATH="/var/lib/minikube/certs/audit-policy.yaml"
NODE_LOG_DIR="/var/log/kubernetes"
NODE_LOG_PATH="${NODE_LOG_DIR}/audit.log"

mkdir -p "${AUDIT_DIR}"

minikube start -p "${PROFILE}" \
  --driver=docker \
  --container-runtime=docker

minikube -p "${PROFILE}" cp "${SCRIPT_DIR}/audit-policy.yaml" "${NODE_POLICY_PATH}"
minikube -p "${PROFILE}" ssh -- "sudo mkdir -p '${NODE_LOG_DIR}' && sudo touch '${NODE_LOG_PATH}' && sudo chmod 0644 '${NODE_LOG_PATH}'"

TMP_MANIFEST="$(mktemp)"
trap 'rm -f "${TMP_MANIFEST}"' EXIT

minikube -p "${PROFILE}" ssh -- "sudo cat /etc/kubernetes/manifests/kube-apiserver.yaml" > "${TMP_MANIFEST}"

python3 - "${TMP_MANIFEST}" "${NODE_POLICY_PATH}" "${NODE_LOG_PATH}" "${NODE_LOG_DIR}" <<'PY'
import sys
from pathlib import Path

manifest_path, policy_path, log_path, log_dir = sys.argv[1:]
text = Path(manifest_path).read_text(encoding="utf-8")

if "--audit-policy-file=" not in text:
    text = text.replace(
        "    - kube-apiserver\n",
        "    - kube-apiserver\n"
        f"    - --audit-policy-file={policy_path}\n"
        f"    - --audit-log-path={log_path}\n"
        "    - --audit-log-maxage=30\n"
        "    - --audit-log-maxbackup=10\n"
        "    - --audit-log-maxsize=100\n",
        1,
    )

if "name: audit-log" not in text:
    text = text.replace(
        "    volumeMounts:\n",
        "    volumeMounts:\n"
        f"    - mountPath: {log_dir}\n"
        "      name: audit-log\n",
        1,
    )
    text = text.replace(
        "  volumes:\n",
        "  volumes:\n"
        "  - hostPath:\n"
        f"      path: {log_dir}\n"
        "      type: DirectoryOrCreate\n"
        "    name: audit-log\n",
        1,
    )

Path(manifest_path).write_text(text, encoding="utf-8")
PY

minikube -p "${PROFILE}" cp "${TMP_MANIFEST}" /tmp/kube-apiserver.yaml
minikube -p "${PROFILE}" ssh -- "sudo cp /tmp/kube-apiserver.yaml /etc/kubernetes/manifests/kube-apiserver.yaml"

echo "Waiting for kube-apiserver to restart with audit configuration..."
for _ in {1..60}; do
  if kubectl --context "${PROFILE}" get --raw=/readyz >/dev/null 2>&1; then
    break
  fi
  sleep 2
done

kubectl --context "${PROFILE}" get --raw=/readyz >/dev/null

kubectl config use-context "${PROFILE}"
echo "Audit-enabled Minikube profile is ready: ${PROFILE}"
echo "Audit log path inside Minikube: ${NODE_LOG_PATH}"
echo "To export it after simulation, run:"
echo "minikube -p ${PROFILE} ssh -- sudo cat ${NODE_LOG_PATH} > ${AUDIT_DIR}/audit.log"
