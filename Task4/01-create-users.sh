#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT_DIR="${SCRIPT_DIR}/generated"
KEY_DIR="${OUT_DIR}/keys"
CSR_DIR="${OUT_DIR}/csr"
CERT_DIR="${OUT_DIR}/certs"
KUBECONFIG_DIR="${OUT_DIR}/kubeconfigs"

mkdir -p "${KEY_DIR}" "${CSR_DIR}" "${CERT_DIR}" "${KUBECONFIG_DIR}"

CURRENT_CONTEXT="$(kubectl config current-context)"
CURRENT_CLUSTER="$(kubectl config view -o "jsonpath={.contexts[?(@.name==\"${CURRENT_CONTEXT}\")].context.cluster}")"
SERVER="$(kubectl config view --raw -o "jsonpath={.clusters[?(@.name==\"${CURRENT_CLUSTER}\")].cluster.server}")"
CA_DATA="$(kubectl config view --raw -o "jsonpath={.clusters[?(@.name==\"${CURRENT_CLUSTER}\")].cluster.certificate-authority-data}")"
CA_PATH="$(kubectl config view --raw -o "jsonpath={.clusters[?(@.name==\"${CURRENT_CLUSTER}\")].cluster.certificate-authority}")"
CA_FILE="${OUT_DIR}/cluster-ca.crt"

if [[ -n "${CA_DATA}" ]]; then
  printf '%s' "${CA_DATA}" | base64 -d > "${CA_FILE}"
elif [[ -n "${CA_PATH}" && -f "${CA_PATH}" ]]; then
  cp "${CA_PATH}" "${CA_FILE}"
else
  echo "Cannot find cluster CA data or CA file in kubeconfig" >&2
  exit 1
fi

users=(
  "ivan-viewer|propdevelopment:viewers|prop-tenant"
  "maria-devops|propdevelopment:platform-configurators|prop-tenant"
  "olga-operator|propdevelopment:product-operators|prop-tenant"
  "sergey-security|propdevelopment:security-admins|prop-tenant"
  "anna-bi|propdevelopment:data-analysts|prop-data"
  "pavel-cluster-admin|propdevelopment:cluster-admins|prop-tenant"
)

for item in "${users[@]}"; do
  IFS='|' read -r username group default_namespace <<< "${item}"
  key_file="${KEY_DIR}/${username}.key"
  csr_file="${CSR_DIR}/${username}.csr"
  cert_file="${CERT_DIR}/${username}.crt"
  kubeconfig_file="${KUBECONFIG_DIR}/${username}.kubeconfig"
  csr_name="csr-${username}"

  if [[ ! -f "${key_file}" ]]; then
    openssl genrsa -out "${key_file}" 2048 >/dev/null 2>&1
    chmod 600 "${key_file}"
  fi

  openssl req -new \
    -key "${key_file}" \
    -out "${csr_file}" \
    -subj "/CN=${username}/O=${group}" >/dev/null 2>&1

  kubectl delete certificatesigningrequest.certificates.k8s.io "${csr_name}" --ignore-not-found >/dev/null

  csr_request="$(base64 -w0 < "${csr_file}")"
  cat <<YAML | kubectl apply -f -
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: ${csr_name}
spec:
  request: ${csr_request}
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: 31536000
  usages:
    - client auth
YAML

  kubectl certificate approve "${csr_name}" >/dev/null

  for _ in {1..20}; do
    cert_data="$(kubectl get certificatesigningrequest.certificates.k8s.io "${csr_name}" -o jsonpath='{.status.certificate}')"
    if [[ -n "${cert_data}" ]]; then
      printf '%s' "${cert_data}" | base64 -d > "${cert_file}"
      break
    fi
    sleep 1
  done

  if [[ ! -s "${cert_file}" ]]; then
    echo "Certificate was not issued for ${username}" >&2
    exit 1
  fi

  kubectl config set-cluster "${CURRENT_CLUSTER}" \
    --server="${SERVER}" \
    --certificate-authority="${CA_FILE}" \
    --embed-certs=true \
    --kubeconfig="${kubeconfig_file}" >/dev/null

  kubectl config set-credentials "${username}" \
    --client-certificate="${cert_file}" \
    --client-key="${key_file}" \
    --embed-certs=true \
    --kubeconfig="${kubeconfig_file}" >/dev/null

  kubectl config set-context "${username}@${CURRENT_CLUSTER}" \
    --cluster="${CURRENT_CLUSTER}" \
    --user="${username}" \
    --namespace="${default_namespace}" \
    --kubeconfig="${kubeconfig_file}" >/dev/null

  kubectl config use-context "${username}@${CURRENT_CLUSTER}" \
    --kubeconfig="${kubeconfig_file}" >/dev/null

  chmod 600 "${kubeconfig_file}"
  echo "Created kubeconfig for ${username}: ${kubeconfig_file}"
done

echo "User certificates and kubeconfigs are stored in ${OUT_DIR}"
