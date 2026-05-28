#!/usr/bin/env bash
set -euo pipefail

kubectl apply -f - <<'YAML'
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: propdevelopment-cluster-admins
subjects:
  - kind: Group
    name: propdevelopment:cluster-admins
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: cluster-admin
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: propdevelopment-viewers-readonly
subjects:
  - kind: Group
    name: propdevelopment:viewers
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: propdevelopment-cluster-readonly
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: propdevelopment-platform-cluster-configurator
subjects:
  - kind: Group
    name: propdevelopment:platform-configurators
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: propdevelopment-cluster-configurator
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: propdevelopment-security-privileged
subjects:
  - kind: Group
    name: propdevelopment:security-admins
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: propdevelopment-security-privileged
  apiGroup: rbac.authorization.k8s.io
YAML

for ns in prop-sales prop-tenant prop-finance prop-data prop-smart-home; do
  kubectl apply -n "${ns}" -f - <<YAML
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: propdevelopment-platform-namespace-configurator
subjects:
  - kind: Group
    name: propdevelopment:platform-configurators
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: propdevelopment-namespace-configurator
  apiGroup: rbac.authorization.k8s.io
YAML
done

for ns in prop-sales prop-tenant prop-finance prop-smart-home; do
  kubectl apply -n "${ns}" -f - <<YAML
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: propdevelopment-product-operator
subjects:
  - kind: Group
    name: propdevelopment:product-operators
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: propdevelopment-product-operator
  apiGroup: rbac.authorization.k8s.io
YAML
done

kubectl apply -n prop-data -f - <<'YAML'
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: propdevelopment-data-analyst
subjects:
  - kind: Group
    name: propdevelopment:data-analysts
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: propdevelopment-data-analyst
  apiGroup: rbac.authorization.k8s.io
YAML

echo "ClusterRoleBindings and RoleBindings were applied"
