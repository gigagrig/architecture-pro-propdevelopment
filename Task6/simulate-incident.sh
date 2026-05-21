#!/bin/bash
set -euo pipefail

kubectl create ns secure-ops --dry-run=client -o yaml | kubectl apply -f -
kubectl config set-context --current --namespace=secure-ops

kubectl wait --for=jsonpath='{.metadata.name}'=default serviceaccount/default -n secure-ops --timeout=60s
kubectl create sa monitoring --dry-run=client -o yaml | kubectl apply -f -
kubectl run attacker-pod --image=alpine --command --dry-run=client -o yaml -- sleep 3600 | kubectl apply -f -
kubectl auth can-i get secrets --as=system:serviceaccount:secure-ops:monitoring || true

KUBE_SYSTEM_SECRET="$(
  kubectl get secrets -n kube-system -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true
)"

if [[ -n "${KUBE_SYSTEM_SECRET}" ]]; then
  kubectl get secret -n kube-system "${KUBE_SYSTEM_SECRET}" \
    --as=system:serviceaccount:secure-ops:monitoring || true
else
  kubectl get secrets -n kube-system \
    --as=system:serviceaccount:secure-ops:monitoring || true
fi

cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: privileged-pod
spec:
  containers:
  - name: pwn
    image: alpine
    command: ["sleep", "3600"]
    securityContext:
      privileged: true
  restartPolicy: Never
EOF

COREDNS_POD=""
for _ in {1..30}; do
  COREDNS_POD="$(kubectl get pods -n kube-system -l k8s-app=kube-dns -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)"
  [[ -n "${COREDNS_POD}" ]] && break
  sleep 2
done

if [[ -n "${COREDNS_POD}" ]]; then
  kubectl exec -n kube-system "${COREDNS_POD}" -- /coredns -version || true
fi

kubectl create configmap audit-policy -n kube-system \
  --from-file=audit-policy.yaml="${BASH_SOURCE%/*}/audit-policy.yaml" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl delete configmap audit-policy -n kube-system --as=admin || true

cat <<'EOF' | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: escalate-binding
subjects:
- kind: ServiceAccount
  name: monitoring
  namespace: secure-ops
roleRef:
  kind: ClusterRole
  name: cluster-admin
  apiGroup: rbac.authorization.k8s.io
EOF
