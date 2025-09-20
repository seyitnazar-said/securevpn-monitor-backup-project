**a. Обзор системы**

Инфраструктура состоит из одной локальной среды (LAN) и трёх виртуальных машин (EC2), развернутых в AWS в зоне доступности us-east-1a, в облаке AWS.

**В локальной сети расположены две машины:**

- Сервер управления (Management Server) — используется для администрирования и подключения к облачным инстансам через SSH.

- Виртуальная машина с Windows 11 — используется в качестве объекта мониторинга с установленным Windows Exporter.

**В AWS развернуты три EC2-инстанса, каждый из которых выполняет отдельную функцию:**

1\. Сервер OpenVPN — обеспечивает VPN-доступ, выдачу сертификатов клиентам и публикацию метрик через OpenVPN Exporter.

2\. Сервер мониторинга — содержит Prometheus, Grafana, Node Exporter и Alertmanager для мониторинга систем.

3\. Сервер хранения — объектное хранилище MinIO (S3-совместимое), используемое для резервного копирования данных с других серверов.

Используемый AWS-аккаунт называется “said devops”. У меня есть полный root-доступ, и управление правами доступа осуществляется через IAM-роли, настроенные для каждой команды.

**Доступ к инфраструктуре организован по командам:**

- Команда VPN — доступ к серверу OpenVPN.

- Команда мониторинга — доступ к серверу мониторинга.

- Команда хранения — доступ к серверу хранения данных.

**Каждому члену команды назначена:**

- IAM-роль для доступа к соответствующим AWS-сервисам (например, для загрузки логов, управления инстансами и т.д.).

- Публичный SSH-ключ, с помощью которого осуществляется подключение к соответствующему EC2-инстансу по SSH.

Часть виртуальных машин была создана вручную через AWS Management Console, а часть — с использованием AWS CLI с сервера управления.

На текущий момент я являюсь единственным системным администратором и ответственным за проект.

<br>

**b. Доменные имена, IP-адреса и полезные ссылки**

Ниже представлен список всех сервисов с соответствующими IP-адресами или доменными именами, а также полезные ссылки.

| Сервис | IP-адрес | Доменное имя | Описание |
| --- | --- | --- | --- |
| Сервер OpenVPN | 3.85.247.98 | —   | Точка доступа для VPN |
| Сервер мониторинга | 3.85.247.92 | prometheus.aviaratours.com | Prometheus, Grafana, Alertmanager |
| Сервер хранения (MinIO) | 3.85.247.96 | minio.aviaratours.com | Объектное хранилище и бэкапы |
| Windows 11 VM (LAN) | 192.168.1.119 | —   | Мониторинг через Windows Exporter |
| Сервер управления (LAN) | 119.235.125.234 | —   | SSH-доступ и AWS CLI |

Полезные ссылки:

• Установка OpenVPN: https://www.cherryservers.com/blog/install-openvpn-server-ubuntu

• Развёртывание MinIO: https://www.atlantic.net/dedicated-server-hosting/how-to-deploy-minio-on-ubuntu-24-04-an-open-source-object-storage-application/

• Установка Prometheus: https://bindplane.com/docs/going-to-production/bindplane/architecture/prometheus/install-manual

<br>

**c. Компоненты системы и их взаимодействие**

**Сервер OpenVPN**

- Обеспечивает защищённое VPN-соединение.

- Генерирует клиентские сертификаты.

- Метрики передаются из OpenVPN Exporter в Prometheus через порт 9176.

**Сервер мониторинга**

- Обеспечивает постоянный мониторинг состояния серверов.

- Визуализирует метрики через Grafana.

- Prometheus собирает метрики с других EC2-инстансов, включая собственный Node Exporter на порту 9100.

**Также осуществляется сбор метрик с:**

- OpenVPN Exporter (порт 9176)

- Windows Exporter на Windows 11 VM (порт 9182)

- При нарушении правил (например, отключение хоста или загрузка CPU ниже 15%) Alertmanager отправляет уведомление на Gmail.

Веб-интерфейс доступен по адресу: https://prometheus.aviaratours.com (требуется аутентификация пользователя).

**Сервер хранения MinIO**

- Используется для хранения \`.sh\`, \`.deb\` файлов и других директорий, отправляемых с сервера управления.

- Адрес: https://minio.aviaratours.com.

- Играет ключевую роль при сбоях: хранит важные данные на случай выхода основного сервера из строя.

**Windows 11 VM (LAN)**

- Работает Windows Exporter на порту 9182.

- Если соединение с VM потеряно или она выключается, Prometheus немедленно отправляет сигнал в Alertmanager.

- Используется в офисе для работы с программами, такими как Microsoft Office и другими служебными утилитами.

**Сервер управления (LAN)**

- Установлен AWS CLI для получения информации об EC2 и их создания.

- Хранит SSH публичные ключи для доступа ко всем EC2-инстансам.

- Содержит cron-задачи, которые автоматически отправляют файлы и директории в MinIO (объектное хранилище).

<br>

**d. Создание EC2-инстансов**

В данной системе используется комбинация ручного управления через AWS Console и автоматизированного через AWS CLI:

**Через AWS Console:**

1\. Авторизация в AWS Management Console под root-аккаунтом.

2\. Выбор региона \*\*us-east-1a\*\*.

3\. Переход в раздел \*\*EC2 → Instances → Launch Instance\*\*.

4\. Выбор образа (Ubuntu) и создание нового ключа доступа (\`.pem\`).

5\. Назначение Elastic IP (статического IP-адреса) инстансу через \*\*Elastic IPs\*\*.

**Через AWS CLI:**

aws ec2 run-instances \\

\--image-id ami-0111190769c4329ae \\

\--instance-type t3.micro \\

\--key-name demo_instance \\

\--subnet-id subnet-XXXXXXXXX \\

\--security-group-ids sg-XXXXXXXXXXX \\

\--tag-specifications 'ResourceType=instance,Tags=\[{{Key=Name,Value=monitoring-server}}\]'

<br>

**Пример установки на OpenVPN-сервере:**

```bash
sudo dpkg -i easy-rsa-installer.deb

sudo dpkg -i openvpn-installer.deb

sudo dpkg -i openvpn-exporter.deb
```

<br>

**Проверьте статус:**

```bash
sudo systemctl status openvpn
```

<br>

**Для мониторинг сервера:**

```bash
sudo dpkg -i prometheus.deb

sudo dpkg -i node exporter

sudo dpkg -i alertmanager-installer.deb
```

<br>

Если пакет уже установлен, данная установка пропускается. Для каждого пакета выводится сообщение, подтверждающее, что пакет уже установлен

<br>

**Удаление установленного пакета:**

```bash
sudo dpkg -r openvpn-installer
```

<br>

**Полное удаление с конфигурацией:**

```bash
sudo dpkg -P openvpn-installer
```

<br>

**MinIO: Установка и настройка**

На отдельном сервере развёрнуто объектное хранилище MinIO. Установка выполняется вручную следующими шагами:

<br>

**Установка MinIO:**

**Скачиваем бинарный файл MinIO с официального сайта через wget**

```bash
wget https://dl.min.io/server/minio/release/linux-amd64/minio
```

<br>

**Делаем файл исполняемым**

```bash
chmod +x minio
```

<br>

**Перемещаем бинарник в системный каталог /usr/local/bin для глобального использования**

```bash
sudo mv minio /usr/local/bin/
```

<br>

**Создание группы, пользователя и директорий**

```bash
sudo groupadd -r minio-user

sudo useradd -M -r -g minio-user minio-user

sudo mkdir /mnt/data
```

<br>

**Назначение владельца** **директорий**

```bash
sudo chown minio-user:minio-user /mnt/data
```

<br>

**Конфигурация MinIO (файл \`/etc/default/minio\`):**

```bash

MINIO_VOLUMES="/mnt/data/"

MINIO_OPTS="-C /etc/minio --address {ip_address}:9000"

MINIO_ROOT_USER={username}

MINIO_ROOT_PASSWORD={password}

MINIO_ACCESS_KEY={access_key}

MINIO_SECRET_KEY={secret_key}
```

<br>

**Systemd unit-файл \`/etc/systemd/system/minio.service\`:**

```bash
[Unit]

Description=Minio

Documentation=https://docs.minio.io

Wants=network-online.target

After=network-online.target

AssertFileIsExecutable=/usr/local/bin/minio



[Service]

WorkingDirectory=/usr/local/

User=minio-user

Group=minio-user

PermissionsStartOnly=true

EnvironmentFile=-/etc/default/minio

ExecStartPre=/bin/bash -c "if [ -z \"${MINIO_VOLUMES}\" ]; then echo \"Variable MINIO_VOLUMES not set in /etc/default/minio\"; exit 1; fi"

ExecStart=/usr/local/bin/minio server $MINIO_OPTS $MINIO_VOLUMES

Restart=on-success

StandardOutput=journal

StandardError=inherit

LimitNOFILE=65536

TimeoutStopSec=0

KillSignal=SIGTERM

SendSIGKILL=no

SuccessExitStatus=0



[Install]

WantedBy=multi-user.target
```

<br>

**Запуск MinIO как службы:**

```bash
sudo systemctl enable minio.service

sudo systemctl start minio

sudo systemctl status minio
```

<br>

**Установка MinIO клиента (\`mc\`) и создание bucket**

**Скачиваем бинарный файл mc с официального сайта через wget**

```bash
wget https://dl.min.io/client/mc/release/linux-amd64/mc
```

<br>

**Делаем файл исполняемым**

```bash
chmod +x mc
```

<br>

**Перемещаем бинарник в системный каталог /usr/local/bin для глобального использования**

```bash
sudo mv mc /usr/local/bin/
```

<br>

**Настройка клиента MinIO и создание бакета**
```bash
mc alias set myminio https://{ip_address}:9000 {username} {password}
```

```bash
mc mb myminio/backup_system
```

<br>

**e. Организация резервного копирования через MinIO**

**Управление и распространение пакетов**

Все \`.deb\` пакеты и скрипты находятся на \*\*Management-сервере\*\*, откуда ежедневно (через cron) отправляются в MinIO-хранилище в папку \`backup_system/\` с временной меткой.

**Доступ для других команд**

Другие команды \*\*не имеют прямого доступа\*\* к MinIO (ни через API, ни через \`mc\`).

MinIO-команда предоставляет доступ к файлам через \`scp\` по запросу:

```bash
scp user@minio-host:/mnt/data/backup_system/backup_2025-07-13.tar.gz .
```

**f. Сервер мониторинга**

**Используемые компоненты:**

- Prometheus — сбор и хранение метрик

- Node Exporter — на всех EC2-инстансах

- OpenVPN Exporter — мониторинг подключений

- Grafana — визуализация

- Alertmanager — уведомления на почту (Gmail)

**Настроенные алерты:**

- Сервер недоступен (ping или node exporter off)

- \`openvpn.service\` отключён или завершён с ошибкой

- Нет подключённых клиентов к OpenVPN

- Windows VM отключена или потеряна связь

- Место на диске < 10%

- VM исчерпала доступную оперативную память
