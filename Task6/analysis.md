# Краткий отчет по анализу audit.log

## Проверяемые события

Скрипт `analyze-audit-log.py` ищет в audit log пять классов событий:

- чтение `secrets` сервисным аккаунтом `system:serviceaccount:secure-ops:monitoring`;
- создание pod с `securityContext.privileged=true`;
- использование `kubectl exec`, которое фиксируется как `create` на подресурсе `pods/exec`;
- попытку удаления audit policy;
- создание `RoleBinding`, который выдает `ClusterRole cluster-admin`.

## Кто инициировал действия

| Действие | Ожидаемый инициатор в audit.log | Комментарий |
| --- | --- | --- |
| Доступ к secrets | `system:serviceaccount:secure-ops:monitoring` | Инициатор задан через `--as`. |
| Создание privileged pod | Пользователь текущего kubeconfig | Обычно `minikube-user` или пользователь из активного kubeconfig. |
| Exec в pod `kube-system` | Пользователь текущего kubeconfig | Действие выполняется без impersonation. |
| Удаление audit policy | `admin` | В симуляции используется `--as=admin`; в реальном кластере запрос может завершиться ошибкой. |
| Создание RoleBinding | Пользователь текущего kubeconfig | Действие выполняется без impersonation. |

## Вредоносные или подозрительные действия

- Чтение secrets сервисным аккаунтом мониторинга: может раскрыть токены, пароли и ключи.
- Создание privileged pod: может привести к выходу из контейнера на уровень ноды.
- Exec в системный pod: позволяет исследовать системный namespace и развивать атаку.
- Попытка удалить audit policy: признак сокрытия следов.
- RoleBinding на `cluster-admin`: прямое повышение привилегий.

## Что считать компрометацией кластера

Компрометацией следует считать успешное чтение чувствительных secrets, успешное создание privileged pod, успешную выдачу `cluster-admin`, а также любую попытку отключить аудит. Даже неуспешные попытки удаления audit policy и доступа к secrets требуют расследования, потому что показывают намерение обойти контроль.

## Ошибки RBAC

- ServiceAccount `monitoring` не должен получать доступ к `secrets`.
- Обычные пользователи и сервисные аккаунты не должны создавать `RoleBinding` на `cluster-admin`.
- Право `pods/exec` в `kube-system` должно быть доступно только эксплуатационным администраторам.
- RBAC не должен быть единственным барьером для privileged pod: нужна Pod Security Admission или admission policy.

## Команды анализа

```bash
./Task6/analyze-audit-log.py ./Task6/minikube-audit/audit.log
./Task6/analyze-audit-log.py --extract-json ./Task6/minikube-audit/audit.log > ./Task6/audit-extract.json
```
