# Анализ инцидентов Kubernetes Audit

## Назначение

Артефакты в директории `Task6` позволяют включить аудит Kubernetes API, выполнить симуляцию подозрительных действий и разобрать `audit.log`.

## Подготовленные файлы

- `audit-policy.yaml` — политика аудита для `pods`, `pods/exec`, `secrets`, `configmaps`, `serviceaccounts`, `roles`, `rolebindings`, `clusterroles`, `clusterrolebindings` и остальных ресурсов на уровне `Metadata`.
- `01-start-minikube-audit.sh` — запуск отдельного профиля Minikube `task6-audit` с audit policy и экспортом audit log.
- `simulate-incident.sh` — симуляция действий из задания.
- `analyze-audit-log.py` — анализатор `audit.log`, который формирует Markdown-отчет.
- `analysis.md` — краткий отчет по выявляемым событиям и выводам.
- `audit-extract.json` — файл для выжимки подозрительных событий; обновляется командой с `--extract-json`.

## Как запустить

```bash
./Task6/01-start-minikube-audit.sh
./Task6/simulate-incident.sh
./Task6/analyze-audit-log.py ./Task6/minikube-audit/audit.log > ./Task6/audit-log-report.md
./Task6/analyze-audit-log.py --extract-json ./Task6/minikube-audit/audit.log > ./Task6/audit-extract.json
```

Если audit log нужно забрать напрямую из Minikube:

```bash
minikube -p task6-audit ssh -- sudo cat /var/log/audit.log > ./Task6/audit.log
./Task6/analyze-audit-log.py ./Task6/audit.log
```

## Подозрительные действия

| Действие | Инициатор | Почему подозрительно | Риск |
| --- | --- | --- | --- |
| Чтение `secrets` | `system:serviceaccount:secure-ops:monitoring` | ServiceAccount для мониторинга не должен читать секреты, особенно в `kube-system`. | Критический |
| Создание privileged pod | Пользователь текущего kubeconfig | Контейнер с `privileged=true` может получить расширенный доступ к ноде. | Критический |
| `kubectl exec` в pod `kube-system` | Пользователь текущего kubeconfig | Exec в системный pod позволяет исследовать окружение и развивать атаку. | Высокий |
| Удаление audit policy | `admin` или пользователь, указанный через impersonation | Попытка отключить аудит является признаком сокрытия активности. | Критический |
| Создание RoleBinding на `cluster-admin` | Пользователь текущего kubeconfig | Выдает ServiceAccount `monitoring` избыточные права администратора. | Критический |

## Что считать компрометацией кластера

- Успешное создание `privileged-pod`.
- Успешное чтение секретов в `kube-system` или чтение secrets неадминистративным ServiceAccount.
- Успешное создание `RoleBinding`, который ссылается на `ClusterRole cluster-admin`.
- Попытка удалить или отключить audit policy, даже если она завершилась ошибкой.

## Ошибки RBAC и защитных политик

- ServiceAccount `monitoring` не должен иметь права `get`, `list` или `watch` для `secrets`.
- Право создавать `RoleBinding` и `ClusterRoleBinding` должно быть доступно только администраторам платформы и проходить через change management.
- `pods/exec` в `kube-system` должен быть запрещен для обычных пользователей и сервисных аккаунтов.
- Создание privileged pod должно блокироваться Pod Security Admission, Kyverno, Gatekeeper или аналогичной admission policy.
- Действия с audit policy и конфигурацией API server должны быть выведены из обычного Kubernetes RBAC и контролироваться на уровне доступа к control plane.

## Рекомендации

- Включить централизованный сбор audit log в SIEM.
- Настроить алерты на чтение secrets, `pods/exec`, privileged pod и выдачу `cluster-admin`.
- Разделить роли мониторинга и эксплуатации: мониторинг получает только read-only метрики и события без доступа к секретам.
- Ввести регулярный review RBAC и поиск wildcard-разрешений.
- Запретить privileged workloads на уровне admission control.
