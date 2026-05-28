# Task 7. PodSecurity and Gatekeeper audit

## Что подготовлено

- `01-create-namespace.yaml` создает namespace `audit-zone` с PodSecurity Admission уровнем `restricted` в режимах `enforce`, `audit` и `warn`.
- `insecure-manifests/` содержит три pod-манифеста с нарушениями: `privileged: true`, `hostPath` и запуск от root.
- `secure-manifests/` содержит исправленные варианты, соответствующие restricted-политике: non-root UID, `runAsNonRoot: true`, `allowPrivilegeEscalation: false`, `seccompProfile: RuntimeDefault`, `capabilities.drop: ["ALL"]`, без `hostPath`, с `readOnlyRootFilesystem: true`.
- `gatekeeper/constraint-templates/` и `gatekeeper/constraints/` описывают запреты для privileged-контейнеров, `hostPath`, root-запуска и отсутствующего `readOnlyRootFilesystem`.
- `audit-policy.yaml` включает аудит создания и изменения pod, namespace и Gatekeeper-ресурсов.

## Предусловия

В кластере должен быть включен PodSecurity Admission. Для проверки Gatekeeper-правил должен быть установлен OPA Gatekeeper.

Пример установки Gatekeeper:

```bash
kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/master/deploy/gatekeeper.yaml
```

## Проверка PodSecurity Admission

```bash
Task7/verify/verify-admission.sh
```

Ожидаемый результат:

- файлы из `insecure-manifests/` отклоняются admission controller;
- файлы из `secure-manifests/` проходят server-side validation.

## Проверка Gatekeeper

```bash
Task7/verify/validate-security.sh
```

Скрипт применяет templates и constraints, ожидает регистрации CRD, затем запускает проверку admission.

## Почему небезопасные манифесты должны блокироваться

- `01-privileged-pod.yaml`: privileged-контейнер получает расширенный доступ к node и нарушает restricted-политику.
- `02-hostpath-pod.yaml`: `hostPath` открывает контейнеру доступ к файловой системе node.
- `03-root-user-pod.yaml`: запуск от UID 0 нарушает требование non-root execution.

