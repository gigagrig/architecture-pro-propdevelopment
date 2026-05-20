# Ролевая модель доступа к Kubernetes

| Роль | Права роли | Группы пользователей |
| --- | --- | --- |
| `cluster-admin` | Полный административный доступ к кластеру. Используется только для платформенной команды, которая отвечает за жизненный цикл кластера, аварийное восстановление и bootstrap RBAC. | `propdevelopment:cluster-admins` - руководитель DevOps/платформенной команды, ограниченный круг администраторов кластера. |
| `propdevelopment-cluster-readonly` | Только чтение ресурсов кластера и namespace: `get`, `list`, `watch` для `namespaces`, `nodes`, `pods`, `pods/log`, `services`, `configmaps`, `deployments`, `jobs`, `ingresses`, `networkpolicies`, `roles`, `rolebindings`. Доступ к `secrets` не выдается. | `propdevelopment:viewers` - бизнес-аналитики, разработчики, менеджеры и аудиторы, которым нужен просмотр состояния без изменения ресурсов. |
| `propdevelopment-cluster-configurator` | Настройка кластерных и namespace-ресурсов без доступа к секретам: создание и изменение `namespaces`, просмотр `nodes`, `storageclasses`, `persistentvolumes`, управление сетевыми политиками, ingress и базовой конфигурацией. Не дает права читать `secrets` и управлять `clusterrolebindings`. | `propdevelopment:platform-configurators` - DevOps-инженеры и инженеры эксплуатации, которые настраивают окружения и сетевые правила. |
| `propdevelopment-namespace-configurator` | Управление рабочими нагрузками внутри продуктовых namespace: `deployments`, `statefulsets`, `daemonsets`, `services`, `configmaps`, `jobs`, `cronjobs`, `ingresses`, `networkpolicies`, `horizontalpodautoscalers`. Доступ к `secrets` исключен. | `propdevelopment:platform-configurators` - применяется через `RoleBinding` в namespace `prop-sales`, `prop-tenant`, `prop-finance`, `prop-data`, `prop-smart-home`. |
| `propdevelopment-product-operator` | Операционная поддержка приложений: просмотр pod/service/deployment/event/log, перезапуск pod через удаление, масштабирование и patch/update `deployments/scale`. Нет доступа к секретам и RBAC. | `propdevelopment:product-operators` - инженеры эксплуатации продуктовых команд и дежурные операционные команды. |
| `propdevelopment-security-privileged` | Привилегированный ИБ-доступ для аудита: чтение `secrets`, `configmaps`, RBAC-объектов, pod/log, network policies и событий безопасности. Изменение workload и выдача прав не разрешены. | `propdevelopment:security-admins` - специалист ИБ и выделенные сотрудники security/audit. |
| `propdevelopment-data-analyst` | Ограниченный просмотр ресурсов аналитического namespace `prop-data`: pod/log, services, configmaps, jobs, cronjobs. Нет доступа к `secrets`, exec и изменениям workload. | `propdevelopment:data-analysts` - BI-аналитики и команды DWH/отчетности. |

## Namespace

| Namespace | Назначение |
| --- | --- |
| `prop-sales` | Сервисы продаж: витрина продаж, онлайн-тур, онлайн-сделка, CRM клиентов, данные недвижимости. |
| `prop-tenant` | Сервисы собственников и ЖКХ: мобильное приложение, `tenant-core-app`, CRM собственников. |
| `prop-finance` | Финансовый контур и бухгалтерский учет. |
| `prop-data` | DWH, BI и отчетность. |
| `prop-smart-home` | Новые сервисы Умный дом и интеграционный слой партнера. |

## Примерные пользователи для проверки

| Пользователь | Группа | Ожидаемый доступ |
| --- | --- | --- |
| `ivan-viewer` | `propdevelopment:viewers` | Просмотр ресурсов без секретов и изменений. |
| `maria-devops` | `propdevelopment:platform-configurators` | Настройка namespace и workload без чтения секретов. |
| `olga-operator` | `propdevelopment:product-operators` | Операционная поддержка приложений в продуктовых namespace. |
| `sergey-security` | `propdevelopment:security-admins` | ИБ-аудит, включая просмотр секретов. |
| `anna-bi` | `propdevelopment:data-analysts` | Просмотр аналитического namespace `prop-data`. |
| `pavel-cluster-admin` | `propdevelopment:cluster-admins` | Полный административный доступ к кластеру. |
