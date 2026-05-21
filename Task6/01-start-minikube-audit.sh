#!/bin/bash
set -euo pipefail

PROFILE="${PROFILE:-task6-audit}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AUDIT_DIR="${SCRIPT_DIR}/minikube-audit"
NODE_POLICY_PATH="/etc/kubernetes/audit-policy.yaml"
NODE_LOG_PATH="/var/log/audit.log"

mkdir -p "${AUDIT_DIR}"

minikube start -p "${PROFILE}" \
  --driver=docker \
  --container-runtime=docker

minikube -p "${PROFILE}" cp "${SCRIPT_DIR}/audit-policy.yaml" "${NODE_POLICY_PATH}"

minikube stop -p "${PROFILE}"

minikube start -p "${PROFILE}" \
  --driver=docker \
  --container-runtime=docker \
  --extra-config=apiserver.audit-policy-file="${NODE_POLICY_PATH}" \
  --extra-config=apiserver.audit-log-path="${NODE_LOG_PATH}" \
  --extra-config=apiserver.audit-log-maxage=30 \
  --extra-config=apiserver.audit-log-maxbackup=10 \
  --extra-config=apiserver.audit-log-maxsize=100

kubectl config use-context "${PROFILE}"
echo "Audit-enabled Minikube profile is ready: ${PROFILE}"
echo "Audit log path inside Minikube: ${NODE_LOG_PATH}"
echo "To export it after simulation, run:"
echo "minikube -p ${PROFILE} ssh -- sudo cat ${NODE_LOG_PATH} > ${AUDIT_DIR}/audit.log"
