#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "Applying PodSecurity namespace"
kubectl apply -f "${ROOT_DIR}/01-create-namespace.yaml"

echo "Applying Gatekeeper constraint templates"
kubectl apply -f "${ROOT_DIR}/gatekeeper/constraint-templates/"

echo "Waiting for Gatekeeper templates to become established"
kubectl wait --for=condition=Established crd/k8sdenyprivileged.constraints.gatekeeper.sh --timeout=120s
kubectl wait --for=condition=Established crd/k8sdenyhostpath.constraints.gatekeeper.sh --timeout=120s
kubectl wait --for=condition=Established crd/k8srequirenonrootreadonly.constraints.gatekeeper.sh --timeout=120s

echo "Applying Gatekeeper constraints"
kubectl apply -f "${ROOT_DIR}/gatekeeper/constraints/"

"${ROOT_DIR}/verify/verify-admission.sh"

echo "Gatekeeper constraints"
kubectl get constraints

