#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

kubectl apply -f "${ROOT_DIR}/01-create-namespace.yaml"

echo "Checking that insecure manifests are rejected in audit-zone"
for manifest in "${ROOT_DIR}"/insecure-manifests/*.yaml; do
  name="$(basename "${manifest}")"
  if kubectl apply --dry-run=server -f "${manifest}" >/tmp/task7-admission.out 2>&1; then
    echo "FAIL: ${name} was accepted, expected rejection"
    cat /tmp/task7-admission.out
    exit 1
  fi
  echo "OK: ${name} rejected"
done

echo "Checking that secure manifests pass admission"
for manifest in "${ROOT_DIR}"/secure-manifests/*.yaml; do
  name="$(basename "${manifest}")"
  kubectl apply --dry-run=server -f "${manifest}" >/tmp/task7-admission.out 2>&1 || {
    echo "FAIL: ${name} was rejected, expected acceptance"
    cat /tmp/task7-admission.out
    exit 1
  }
  echo "OK: ${name} accepted"
done

rm -f /tmp/task7-admission.out

