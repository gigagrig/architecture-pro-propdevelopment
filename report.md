# Отчет по заданию 1

Выполнено задание 1 проектной работы 5: подготовлен проверочный лист по безопасности данных в формате mindmap draw.io.

Создан файл:

- `Task1/data-security-mindmap.drawio`

Что сделано:

- Проанализированы описание PropDevelopment и контейнерная диаграмма `PropDevelopmnent-diagram.xml`.
- Выделены четыре категории данных по подходу ISO/IEC 27001/27002: публичные, внутренние, конфиденциальные и секретные.
- Для каждой категории указаны конкретные типы данных из ландшафта PropDevelopment.
- Для типов данных определены актуальные риски: утечка, потеря, искажение, некачественные данные, обесценивание.
- Каждому риску присвоена оценка по шкале: незначительный, значительный, критический.
- Для каждой оценки добавлено краткое обоснование.

Ключевые выводы:

- Наиболее критичные зоны: персональные данные клиентов и собственников, данные сделок, платежные и ЖКХ-данные, сырые данные DWH, учетные данные и секреты интеграций.
- Основная причина высоких рисков: несколько точек регистрации клиента, слабый системный контроль внутренних потоков данных, CDC-передача сырых данных в DWH и небезопасные партнерские API.
- Публичные данные имеют в основном значимые риски искажения и качества, но риск утечки для них несущественный.
- Внутренние данные важны для устойчивой эксплуатации и развития BI/ML/AI, поэтому для них существенны риски утечки, искажения и обесценивания.
- Конфиденциальные и секретные данные требуют первоочередного контроля доступа, маскирования, аудита, сегментации потоков и регулярной проверки контрактов API.

# Отчет по заданию 2

Выполнено задание 2 проектной работы 5: подготовлен проверочный лист безопасности для бизнес-систем PropDevelopment в формате Markdown-таблицы.

Создан файл:

- `Task2/business-systems-security-checklist.md`

Что сделано:

- Проанализированы описание PropDevelopment, контейнерная диаграмма `PropDevelopmnent-diagram.xml` и результаты задания 1.
- Идентифицированы ключевые бизнес-системы и области проверки: сервисы продаж, сервисы собственников и ЖКХ, финансовый контур, DWH/BI, службы аутентификации, Active Directory и внешние интеграции.
- Выбраны разделы чеклиста с учетом проблем компании: управление доступом, безопасность данных, API и интеграции, инфраструктура и сеть, резервное восстановление, аудит и мониторинг, Data Governance, управление инцидентами.
- Для каждого раздела добавлено обоснование выбора.
- Заполнена Markdown-таблица из 42 контрольных вопросов со статусами `Да`, `Нет` и `Неизвестно`.
- Добавлена таблица приоритетов устранения выявленных пробелов.

Ключевые выводы:

- Наиболее критичные пробелы связаны с партнерскими API управляющих компаний, объектной авторизацией, смешением клиентских профилей и неконтролируемой передачей сырых данных в DWH.
- Подтвержденные меры безопасности: наличие firewall для внешнего доступа, Active Directory для внутренних пользователей, отдельный финансовый контур AD и резервное копирование БД.
- Неподтвержденные зоны, которые необходимо проверить на аудите: MFA, шифрование данных и каналов, защита резервных копий, регулярное тестирование восстановления, SIEM/централизованные логи, сегментация сети и процесс lifecycle management учетных записей.
- Приоритет P1 рекомендуется назначить security review партнерских API, объектной авторизации и ограничению доступа к ПДн в DWH/BI.

# Отчет по заданию 3

Выполнено задание 3 проектной работы 5: подготовлены архитектурные артефакты для подключения партнерских сервисов Умный дом.

Созданы файлы:

- `Task3/smart-home-context.drawio`
- `Task3/smart-home-container.drawio`
- `Task3/smart-home-integration-requirements.md`

Что сделано:

- Подготовлена C4-диаграмма контекста для интеллектуального домофона и интеллектуального шлагбаума.
- Подготовлена обновленная контейнерная диаграмма для группы сервисов ЖКУ.
- В архитектуру добавлен новый контейнер `smart-home-integration-app` как антикоррупционный слой между `tenant-core-app` и внешней платформой партнера.
- Добавлена новая БД `smart-home-db` для согласий, привязок устройств, разрешений и журнала событий.
- Описаны требования к безопасности, аутентификации, авторизации и взаимодействию PropDevelopment с внешней платформой.

Ключевые выводы:

- Внешний партнерский API не должен вызываться напрямую из мобильного приложения; все команды проходят через контролируемый backend PropDevelopment.
- Для интеграции рекомендованы OIDC Authorization Code + PKCE для мобильного приложения, service JWT или mTLS внутри контура и mTLS + OAuth2 Client Credentials для взаимодействия с партнером.
- Критичные проверки: объектная авторизация по собственнику, ЖК, дому, подъезду и помещению; минимизация данных; явные согласия на биометрию и номера автомобилей; централизованный аудит.
- Биометрия, видеопотоки и номера автомобилей не должны попадать в DWH/BI и ML/AI-контуры без отдельного правового основания, согласия и обезличивания.

# Отчет по заданию 4

Выполнено задание 4 проектной работы 5: подготовлена ролевая модель Kubernetes RBAC, скрипты создания пользователей, ролей и привязок.

Созданы файлы:

- `Task4/rbac-table.md`
- `Task4/01-create-users.sh`
- `Task4/02-create-roles.sh`
- `Task4/03-bind-roles.sh`
- `Task4/.gitignore`

Что сделано:

- Запущен пустой Minikube и проверен доступ к API Kubernetes.
- Подготовлена таблица ролей и соответствующих групп пользователей по оргструктуре PropDevelopment.
- Выделены группы `viewers`, `platform-configurators`, `product-operators`, `security-admins`, `data-analysts`, `cluster-admins`.
- Скрипт `01-create-users.sh` создает тестовых пользователей через Kubernetes CSR и выпускает kubeconfig-файлы.
- Скрипт `02-create-roles.sh` создает namespace и ClusterRole.
- Скрипт `03-bind-roles.sh` создает ClusterRoleBinding и RoleBinding.
- Сгенерированные приватные ключи, сертификаты и kubeconfig-файлы исключены из PR через `Task4/.gitignore`.

Ключевые выводы:

- Просмотр ресурсов без секретов отделен от привилегированного ИБ-доступа.
- Привилегированное чтение `secrets` выдано только группе `propdevelopment:security-admins`.
- Настройка окружений и эксплуатационные действия разделены: DevOps может конфигурировать namespace, операционные команды могут смотреть логи, масштабировать workload и перезапускать pod без доступа к секретам.
- Для аналитического контура выделен отдельный доступ к namespace `prop-data` без доступа к секретам и без изменения workload.

# Отчет по заданию 5

Выполнено задание 5 проектной работы 5: подготовлена и проверена сетевая политика Kubernetes для разграничения трафика между четырьмя сервисами.

Создан файл:

- `Task5/non-admin-api-allow.yaml`

Что сделано:

- В namespace `task5-traffic` развернуты четыре nginx-сервиса с метками `role=front-end`, `role=back-end-api`, `role=admin-front-end`, `role=admin-back-end-api`.
- Подготовлен набор NetworkPolicy: default deny для ingress/egress, разрешение DNS egress и allow-политики для двух разрешенных пар.
- Для корректной проверки создан отдельный профиль Minikube `task5-netpol` с Calico CNI, так как стандартный профиль Minikube принимал NetworkPolicy, но не применял их на уровне сети.
- Политики применены командой `kubectl apply -n task5-traffic -f Task5/non-admin-api-allow.yaml`.

Проверка трафика:

- `front-end -> back-end-api`: разрешено, nginx отвечает.
- `back-end-api -> front-end`: разрешено, nginx отвечает.
- `admin-front-end -> admin-back-end-api`: разрешено, nginx отвечает.
- `admin-back-end-api -> admin-front-end`: разрешено, nginx отвечает.
- `front-end -> admin-back-end-api`: запрещено, `wget` завершается по timeout.
- `admin-front-end -> back-end-api`: запрещено, `wget` завершается по timeout.

Ключевой вывод:

- Изоляция работает только при CNI с поддержкой NetworkPolicy. На профиле `task5-netpol` с Calico запрещенный межконтурный трафик блокируется корректно.

# Отчет по заданию 6

Выполнено задание 6 проектной работы 5: подготовлены политика аудита Kubernetes, симуляция инцидента и анализатор audit log.

Созданы файлы:

- `Task6/audit-policy.yaml`
- `Task6/01-start-minikube-audit.sh`
- `Task6/simulate-incident.sh`
- `Task6/analyze-audit-log.py`
- `Task6/analysis.md`
- `Task6/audit-extract.json`
- `Task6/audit-incident-analysis.md`

Что сделано:

- Подготовлена audit policy с уровнем `RequestResponse` для чувствительных ресурсов: `pods`, `pods/exec`, `secrets`, `configmaps`, `serviceaccounts`, `roles`, `rolebindings`, `clusterroles`, `clusterrolebindings`.
- Добавлен скрипт запуска отдельного профиля Minikube `task6-audit` с audit log в `/var/log/audit.log` внутри Minikube и командой экспорта в `Task6/minikube-audit/audit.log`.
- Добавлен скрипт `simulate-incident.sh`, который воспроизводит действия из задания: попытку доступа к secrets, создание privileged pod, exec в системный pod, попытку удаления audit policy и создание RoleBinding на `cluster-admin`.
- Подготовлен Python-анализатор `analyze-audit-log.py`, который ищет подозрительные события и может формировать Markdown-отчет или JSON-выжимку для `audit-extract.json`.
- Подготовлен краткий отчет `analysis.md` с описанием инициаторов, вредоносных действий, критериев компрометации и ошибок RBAC.

Ключевые выводы:

- Критичными событиями считаются успешное чтение secrets, создание privileged pod и выдача `cluster-admin` через RoleBinding.
- Попытка отключить или удалить audit policy является индикатором сокрытия следов и требует расследования даже при неуспешном ответе API.
- RBAC должен ограничивать доступ ServiceAccount `monitoring` к secrets, создание RoleBinding на `cluster-admin` и использование `pods/exec` в системных namespace.
- Для блокировки privileged workloads одного RBAC недостаточно: нужна Pod Security Admission, Kyverno, Gatekeeper или другой admission-контроль.

# Отчет по заданию 7

Выполнено задание 7 проектной работы 5: подготовлены политики безопасности pod с применением PodSecurity Admission и OPA Gatekeeper.

Созданы файлы:

- `Task7/01-create-namespace.yaml`
- `Task7/insecure-manifests/01-privileged-pod.yaml`
- `Task7/insecure-manifests/02-hostpath-pod.yaml`
- `Task7/insecure-manifests/03-root-user-pod.yaml`
- `Task7/secure-manifests/01-secure.yaml`
- `Task7/secure-manifests/02-secure.yaml`
- `Task7/secure-manifests/03-secure.yaml`
- `Task7/gatekeeper/constraint-templates/privileged.yaml`
- `Task7/gatekeeper/constraint-templates/hostpath.yaml`
- `Task7/gatekeeper/constraint-templates/runasnonroot.yaml`
- `Task7/gatekeeper/constraints/privileged.yaml`
- `Task7/gatekeeper/constraints/hostpath.yaml`
- `Task7/gatekeeper/constraints/runasnonroot.yaml`
- `Task7/verify/verify-admission.sh`
- `Task7/verify/validate-security.sh`
- `Task7/audit-policy.yaml`
- `Task7/README_FOR_REVIEWER.md`

Что сделано:

- Создан namespace `audit-zone` с PodSecurity Admission уровнем `restricted` в режимах `enforce`, `audit` и `warn`.
- Подготовлены три небезопасных манифеста: privileged pod, pod с `hostPath` и pod с запуском от UID 0.
- Подготовлены исправленные манифесты с `runAsNonRoot: true`, non-root UID, `allowPrivilegeEscalation: false`, `seccompProfile: RuntimeDefault`, `capabilities.drop: ["ALL"]`, `readOnlyRootFilesystem: true` и без `hostPath`.
- Настроены Gatekeeper ConstraintTemplate и Constraint для запрета `privileged: true`, `hostPath`, запуска от root и отсутствия `readOnlyRootFilesystem`.
- Добавлены проверочные скрипты для server-side admission-проверки и применения Gatekeeper-политик.

Проверка:

- `Task7/verify/verify-admission.sh`: небезопасные манифесты отклоняются, безопасные проходят.
- `Task7/verify/validate-security.sh`: Gatekeeper templates и constraints применяются, ограничения работают в режиме `deny`.

Ключевой вывод:

- PodSecurity Admission закрывает базовые нарушения restricted-профиля на уровне namespace, а Gatekeeper добавляет явные проверяемые политики, включая обязательный `readOnlyRootFilesystem`.
