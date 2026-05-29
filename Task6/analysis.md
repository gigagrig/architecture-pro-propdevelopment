# Краткий отчет по анализу audit.log

## Проверяемые события

Скрипт `analyze-audit-log.py` ищет в audit log пять классов событий:

- чтение `secrets` сервисным аккаунтом `system:serviceaccount:secure-ops:monitoring`;
- создание pod с `securityContext.privileged=true`;
- использование `kubectl exec`, которое в текущем `audit.log` фиксируется как запрос к подресурсу `pods/exec` с кодом ответа `101`;
- попытку удаления audit policy;
- создание `RoleBinding`, который выдает `ClusterRole cluster-admin`.

## Выявленные события

| Действие | Инициатор | Объект | Код ответа | Комментарий |
| --- | --- | --- | --- | --- |
| Доступ к secrets | `system:serviceaccount:secure-ops:monitoring` | `kube-system/secrets/bootstrap-token-ur1ufg` | `403` | Инициатор задан через `--as`; попытка чтения запрещена RBAC. |
| Создание privileged pod | `minikube-user` | `secure-ops/pods/privileged-pod` | `201` | Pod создан с `securityContext.privileged=true`. |
| Exec в pod `kube-system` | `minikube-user` | `kube-system/pods/exec/coredns-7d764666f9-nmnpj` | `101` | Запрос `kubectl exec` прошел upgrade-сессию к pod в системном namespace. |
| Удаление audit policy | `admin` | `kube-system/configmaps/audit-policy` | `403` | В симуляции audit policy представлена временным `ConfigMap`; запрос выполнен через `--as=admin` и запрещен RBAC. |
| Создание RoleBinding | `minikube-user` | `secure-ops/rolebindings/escalate-binding` | `201` | RoleBinding выдал `ClusterRole cluster-admin` сервисному аккаунту `monitoring`. |

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
