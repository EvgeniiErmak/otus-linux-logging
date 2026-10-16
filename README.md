# OTUS Linux Professional — центральный сервер сбора логов

## Задание
- Две машины: **web** и **log**; на web — nginx.
- Центральный лог-сервер — **rsyslog** (как в методичке).
- **auditd** отслеживает изменения конфигурации nginx.
- Критичные логи web — локально и удалённо.
- Все логи nginx — на удалённый сервер (локально только `crit`).
- Логи аудита — на удалённую систему.
- ⭐ Дополнительно **ELK**: в ELK только логи nginx, в rsyslog — всё остальное.

## Стенд
| Роль | Хост | IP | Сервисы |
|---|---|---|---|
| web | ПК-1 | 192.168.88.238 | nginx, auditd + audisp-syslog, rsyslog (клиент), Ansible |
| log | ПК-2 | 192.168.88.239 | rsyslog (сервер, TCP/UDP 514) |
| elk ⭐ | ПК-2 (Docker) | 192.168.88.239 | Elasticsearch :9200, Logstash :5140/udp, Kibana :5601 |

ОС: Ubuntu 26.04. Для запуска в виртуальных машинах — [Vagrantfile](Vagrantfile) (тот же playbook).

## Структура репозитория
- [Vagrantfile](Vagrantfile) — ВМ web / log / elk с провижинингом Ansible
- [ansible.cfg](ansible.cfg), [inventory/hosts.ini](inventory/hosts.ini), [group_vars/all.yml](group_vars/all.yml)
- [site.yml](site.yml) — основной playbook
- [roles/common](roles/common) — hostname, /etc/hosts, часовой пояс, chrony
- [roles/log](roles/log) — rsyslog-сервер ([10-remote.conf](roles/log/templates/10-remote.conf.j2))
- [roles/web](roles/web) — nginx ([nginx.conf](roles/web/templates/nginx.conf.j2)), правила аудита ([nginx.rules](roles/web/files/nginx.rules)), пересылка crit и аудита, параметр ядра `audit=1`
- [roles/elk](roles/elk) — ELK в Docker
- [scripts/create_repo.sh](scripts/create_repo.sh) — создание репозитория и push
- [screenshots](screenshots) — скриншоты выполнения

## Запуск
```bash
# Базовое задание: nginx -> rsyslog
ansible-playbook site.yml --skip-tags elk

# Задание со звёздочкой: nginx -> ELK, остальное -> rsyslog
ansible-playbook site.yml -e nginx_log_target=elk
```

## Куда идут логи
| Источник | Локально (web) | Удалённо |
|---|---|---|
| nginx access | нет | `log:/var/log/rsyslog/web/nginx_access.log` (⭐ ELK, индекс `nginx-*`) |
| nginx error | `/var/log/nginx/error.log` (только crit) | `log:/var/log/rsyslog/web/nginx_error.log` (⭐ ELK) |
| `*.crit` | `/var/log/crit.log` | `log:/var/log/rsyslog/web/critical.log` |
| auditd (`-k nginx_conf`) | `/var/log/audit/audit.log` | `log:/var/log/rsyslog/web/audit.log` |

## Особенности
- На `log` отключено `$RepeatedMsgReduction`, иначе одинаковые строки access-лога сворачиваются.
- На `web` задан параметр ядра `audit=1`: без него не аудируются процессы, запущенные до старта auditd.
