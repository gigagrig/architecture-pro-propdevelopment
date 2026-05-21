#!/usr/bin/env python3
import argparse
import json
import sys
from collections import Counter
from pathlib import Path


def get_path(data, *path, default=None):
    current = data
    for key in path:
        if not isinstance(current, dict):
            return default
        current = current.get(key)
        if current is None:
            return default
    return current


def is_privileged_pod(event):
    request_object = event.get("requestObject") or {}
    if request_object.get("kind") != "Pod":
        return False
    spec = request_object.get("spec") or {}
    containers = spec.get("containers") or []
    init_containers = spec.get("initContainers") or []
    for container in containers + init_containers:
        security_context = container.get("securityContext") or {}
        if security_context.get("privileged") is True:
            return True
    return False


def effective_user(event):
    return get_path(
        event,
        "impersonatedUser",
        "username",
        default=get_path(event, "user", "username", default=""),
    )


def summarize_event(event, incident_type, severity, reason):
    object_ref = event.get("objectRef") or {}
    response_status = event.get("responseStatus") or {}
    return {
        "type": incident_type,
        "severity": severity,
        "stage": event.get("stage", ""),
        "timestamp": event.get("requestReceivedTimestamp", ""),
        "user": effective_user(event),
        "authenticated_user": get_path(event, "user", "username", default=""),
        "verb": event.get("verb", ""),
        "namespace": object_ref.get("namespace", ""),
        "resource": object_ref.get("resource", ""),
        "subresource": object_ref.get("subresource", ""),
        "name": object_ref.get("name", ""),
        "code": response_status.get("code", ""),
        "reason": reason,
    }


def classify(event):
    if event.get("stage") != "ResponseComplete":
        return []

    object_ref = event.get("objectRef") or {}
    user = effective_user(event)
    verb = event.get("verb", "")
    resource = object_ref.get("resource", "")
    subresource = object_ref.get("subresource", "")
    namespace = object_ref.get("namespace", "")
    name = object_ref.get("name", "")
    api_group = object_ref.get("apiGroup", "")

    findings = []

    if (
        resource == "secrets"
        and verb in {"get", "list"}
        and user == "system:serviceaccount:secure-ops:monitoring"
    ):
        findings.append(
            summarize_event(
                event,
                "service-account-secret-access",
                "high",
                "ServiceAccount monitoring attempts to read Kubernetes secrets.",
            )
        )

    if verb == "create" and resource == "pods" and namespace == "secure-ops" and is_privileged_pod(event):
        findings.append(
            summarize_event(
                event,
                "privileged-pod-created",
                "critical",
                "A pod is created with securityContext.privileged=true.",
            )
        )

    if resource == "pods" and subresource == "exec" and verb in {"create", "get"}:
        findings.append(
            summarize_event(
                event,
                "exec-into-pod",
                "high",
                "kubectl exec is used inside a running pod.",
            )
        )

    if verb == "delete" and (
        (resource == "configmaps" and name == "audit-policy")
        or api_group == "audit.k8s.io"
        or resource in {"policies", "auditpolicies"}
    ):
        findings.append(
            summarize_event(
                event,
                "audit-policy-delete-attempt",
                "critical",
                "There is an attempt to delete an audit policy object.",
            )
        )

    request_object = event.get("requestObject") or {}
    role_ref = request_object.get("roleRef") or {}
    if (
        verb == "create"
        and resource == "rolebindings"
        and role_ref.get("kind") == "ClusterRole"
        and role_ref.get("name") == "cluster-admin"
    ):
        findings.append(
            summarize_event(
                event,
                "cluster-admin-rolebinding-created",
                "critical",
                "A RoleBinding grants cluster-admin privileges inside a namespace.",
            )
        )

    return findings


def read_events(path):
    raw = path.read_text(encoding="utf-8").strip()
    if not raw:
        return

    if raw.startswith("["):
        try:
            events = json.loads(raw)
        except json.JSONDecodeError as error:
            print(f"Skipping invalid JSON array: {error}", file=sys.stderr)
            return
        for event in events:
            if isinstance(event, dict):
                yield event
            else:
                print("Skipping non-object item in JSON array", file=sys.stderr)
        return

    with path.open("r", encoding="utf-8") as audit_log:
        for line_number, line in enumerate(audit_log, start=1):
            line = line.strip()
            if not line:
                continue
            try:
                event = json.loads(line)
            except json.JSONDecodeError as error:
                print(f"Skipping invalid JSON at line {line_number}: {error}", file=sys.stderr)
                continue
            if isinstance(event, dict):
                yield event
            else:
                print(f"Skipping non-object JSON at line {line_number}", file=sys.stderr)


def print_markdown(findings, total_events):
    print("# Анализ audit.log")
    print()
    print(f"Всего событий в audit.log: {total_events}")
    print(f"Найдено подозрительных событий: {len(findings)}")
    print()

    if not findings:
        print("Подозрительные события по правилам анализатора не найдены.")
        return

    print("| Тип события | Риск | Инициатор | Действие | Объект | Код ответа | Обоснование |")
    print("| --- | --- | --- | --- | --- | --- | --- |")
    for finding in findings:
        object_name = "/".join(
            part
            for part in [
                finding["namespace"],
                finding["resource"],
                finding["subresource"],
                finding["name"],
            ]
            if part
        )
        print(
            "| {type} | {severity} | {user} | {verb} | {object_name} | {code} | {reason} |".format(
                object_name=object_name,
                **finding,
            )
        )

    print()
    print("## Сводка по инициаторам")
    users = Counter(finding["user"] for finding in findings)
    for user, count in users.most_common():
        print(f"- `{user}`: {count}")

    print()
    print("## Что считать компрометацией")
    print("- Успешное создание privileged pod.")
    print("- Успешное чтение secret в `kube-system` или другим неадминистративным ServiceAccount.")
    print("- Успешное создание RoleBinding на `cluster-admin` без change request.")
    print("- Попытка отключить или удалить audit policy, даже если API вернул ошибку.")

    print()
    print("## Ошибки RBAC")
    print("- ServiceAccount `monitoring` не должен иметь доступ к secrets.")
    print("- Создание RoleBinding на `cluster-admin` должно быть ограничено администраторами кластера.")
    print("- `pods/exec` в системных namespace должен быть доступен только узкому кругу эксплуатационных ролей.")
    print("- Создание privileged pod должно блокироваться Pod Security Admission или admission policy.")


def main():
    parser = argparse.ArgumentParser(description="Find suspicious events in Kubernetes audit.log")
    parser.add_argument("audit_log", help="Path to audit.log")
    parser.add_argument(
        "--extract-json",
        action="store_true",
        help="Print suspicious events as JSON instead of a Markdown report",
    )
    args = parser.parse_args()

    audit_log_path = Path(args.audit_log)
    findings = []
    total_events = 0
    for event in read_events(audit_log_path):
        total_events += 1
        findings.extend(classify(event))

    if args.extract_json:
        print(json.dumps(findings, ensure_ascii=False, indent=2))
    else:
        print_markdown(findings, total_events)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
