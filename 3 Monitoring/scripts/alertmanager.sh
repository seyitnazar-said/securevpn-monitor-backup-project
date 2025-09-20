#!/bin/bash
#
# This script automates the deployment of alertmanager for prometheus monitoring server
# Author: Said
# Email: arabovseyitnazar@gmail.com

###################################
# Print a given message in color
# Arguments:
#   Color.    eg: green, red
###################################
function print_color(){

  case $1 in
    "green") COLOR="\033[0;32m" ;;
    "red") COLOR="\033[0;31m" ;;
    "*") COLOR="\033[0m" ;;
  esac

  echo -e "${COLOR} $2 ${NC}"
}

###################################
# Print a service status
# Arguments:
#   Service.    eg: prometheus, alertmanager
###################################
function check_service_status(){

  is_service_active=$(systemctl is-active $1)

  if [ $is_service_active = "active" ]
  then
    print_color "green" "$1 Service is active"
  else
    print_color "red" "$1 Service is not active"
    exit 1
  fi
}

# variables for alertmanager service
package="/home/ubuntu/alertmanager"
alertmanager_conf="/etc/alertmanager/alertmanager.yml"
alertmanager_bin="/usr/local/bin/alertmanager"
amtool_bin="/usr/local/bin/amtool"
service="/etc/systemd/system/alertmanager.service"
rules="/etc/prometheus/alertrules.yml"

#---------------------ALERTMANAGER CONFIGURATION-----------------------
# "User, group and directory management"
print_color "green" "create alertmanager user, group and directory and set ownership"

if ! getent group alertmanager >/dev/null; then
    sudo groupadd -f alertmanager
fi

if ! id -u alertmanager >/dev/null 2>&1; then
    sudo useradd --no-create-home \
                 --shell /bin/false \
                 --gid alertmanager \
                 alertmanager
fi

sudo install -d -o alertmanager -g alertmanager -m 755 /etc/alertmanager
sudo install -d -o alertmanager -g alertmanager -m 755 /var/lib/alertmanager

# "Install alertmanager, change ownership and create a service file"
print_color "green" "move binary files"
cd "$package"
sudo mv alertmanager "$alertmanager_bin"
sudo mv amtool "$amtool_bin"
sudo mv alertmanager.yml "$alertmanager_conf"

print_color "green" "change ownership"
sudo chown alertmanager:alertmanager "$alertmanager_bin"
sudo chown alertmanager:alertmanager "$amtool_bin"
sudo chown alertmanager:alertmanager "$alertmanager_conf"

print_color "green" "creating a service file"
if [ ! -f "$service" ]; then
  sudo touch "$service"
else
  print_color "green" "File "$service" already exists, skipping create."
fi

print_color "green" "inserting the necessary parameters and values into the service file"
if ! grep -q "alertmanager.yml" "$service"; then
  sudo tee -a "$service" >/dev/null <<'EOF'
[Unit]
Description=AlertManager
Wants=network-online.target
After=network-online.target

[Service]
User=alertmanager
Group=alertmanager
Type=simple
ExecStart=/usr/local/bin/alertmanager \
    --config.file /etc/alertmanager/alertmanager.yml \
    --storage.path /var/lib/alertmanager/

[Install]
WantedBy=multi-user.target

EOF
fi

print_color "green" "change mode of the service"
sudo chmod 664 "$service"

print_color "green" "check if data was loaded"
results=$(sudo cat "$service")

if [[ "$results" == *alertmanager* ]]
then
  print_color "green" "information data loaded"
else
  print_color "red" "information data not loaded"
  exit 1
fi

print_color "green" "check status of the alertmanager service"
sudo systemctl daemon-reload
sudo systemctl start alertmanager.service
sudo systemctl enable alertmanager.service
sudo systemctl restart alertmanager.service
check_service_status alertmanager

print_color "green" "copy a backup file"
sudo cp "$alertmanager_conf" "$alertmanager_conf.bak"

print_color "green" "configure alertmanager.yml file for gmail alerts"
if ! grep -q "smtp.gmail.com:465" "$alertmanager_conf"; then
  sudo tee "$alertmanager_conf" >/dev/null <<'EOF'
global:
  # The smarthost and SMTP sender used for mail notifications.
  smtp_smarthost: 'smtp.gmail.com:465'
  smtp_from: 'microfollower@gmail.com'
  smtp_auth_username: 'microfollower@gmail.com'
  smtp_auth_password: 'vyunsyqzeogerfrr'
  smtp_require_tls: false
# The directory from which notification templates are read.
templates:
- '/etc/alertmanager/templates/*.tmpl'

# The root route on which each incoming alert enters.
route:
  # The labels by which incoming alerts are grouped together. For example,
  # multiple alerts coming in for cluster=A and alertname=LatencyHigh would
  # be batched into a single group.
  group_by: ['alertname', 'cluster', 'service', 'network', 'system_alerts']

  # When a new group of alerts is created by an incoming alert, wait at
  # least 'group_wait' to send the initial notification.
  # This way ensures that you get multiple alerts for the same group that start
  # firing shortly after another are batched together on the first
  # notification.
  group_wait: 30s

  # When the first notification was sent, wait 'group_interval' to send a batch
  # of new alerts that started firing for that group.
  group_interval: 1m

  # If an alert has successfully been sent, wait 'repeat_interval' to
  # resend them.
  repeat_interval: 3h

  # A default receiver
  receiver: 'email-me'

  # All the above attributes are inherited by all child routes and can
  # overwritten on each.

  # The child route trees.
  routes:
#  - receiver: 'email-me'
 #   matchers:
  #  - severity: 'warning'
   # - alertname: 'ExampleRedisGroup'

  # This routes performs a regular expression match on alert labels to
  # catch alerts that are related to a list of services.
  - match_re:
      service: ^(foo1|foo2|baz)$
    receiver: email-me
    # The service has a sub-route for critical alerts, any alerts
    # that do not match, i.e. severity != critical, fall-back to the
    # parent node and are sent to 'team-X-mails'
    routes:
    - match:
        severity: 'warning'
      receiver: 'email-me'
  - match:
      service: 'files'
    receiver: 'email-me'

    routes:
    - match:
        severity: 'warning'
      receiver: 'email-me'

  # This route handles all alerts coming from a database service. If there's
  # no team to handle it, it defaults to the DB team.
  - match:
      service: database
    receiver: team-DB-pager
    # Also group alerts by affected database.
    group_by: [alertname, cluster, database]
    routes:
    - match:
        owner: team-X
      receiver: team-X-pager
    - match:
        owner: team-Y
      receiver: team-Y-pager

# Inhibition rules allow to mute a set of alerts given that another alert is
# firing.
# We use this to mute any warning-level notifications if the same alert is
# already critical.
inhibit_rules:
- source_match:
    severity: 'critical'
  target_match:
    severity: 'warning'
  # Apply inhibition if the alertname is the same.
  equal: ['alertname', 'cluster', 'service']

receivers:
- name: 'email-me'
  email_configs:
  - to: 'microfollower@gmail.com'

- name: 'team-X-mails'
  email_configs:
  - to: 'team-X+alerts@example.org'

- name: 'team-X-pager'
  email_configs:
  - to: 'team-X+alerts-critical@example.org'
  pagerduty_configs:
  - service_key: <team-X-key>

- name: 'team-Y-mails'
  email_configs:
  - to: 'team-Y+alerts@example.org'

- name: 'team-Y-pager'
  pagerduty_configs:
  - service_key: <team-Y-key>

- name: 'team-DB-pager'
  pagerduty_configs:
  - service_key: <team-DB-key>

EOF
fi

print_color "green" "creating rules file"
if [ ! -f "$rules" ]; then
  sudo touch "$rules"
else
  print_color "green" "File "$rules" already exists, skipping create."
fi

print_color "green" "creating alert rules"
if ! grep -q "windows-vm" "$rules"; then
  sudo tee "$rules" >/dev/null <<'EOF'
groups:
  - name: Windows vm
    rules:
    - alert: Windows vm is Down
      expr: up{instance="192.168.1.119:9182"} == 0
      for: 20s
      labels:
        severity: critical
        service: windows-vm
      annotations:
        summary: "Windows machine at 192.168.1.119 is down"
        description: "Instance 192.168.1.119 has been down for more than 20s."

    - alert: Low disk space
      expr: (node_filesystem_avail_bytes{fstype!~"^(fuse.*|tmpfs|cifs|nfs)"} / node_filesystem_size_bytes < .10 and on (instance, device, mountpoint) node_filesystem_readonly == 0)
      for: 20s
      labels:
        severity: critical
      annotations:
        summary: "VM out of disk space (instance {{ $labels.instance }})"
        description: "Disk is almost full (< 10% left)\n VALUE= {{ $value }}\n LABELS = {{ $labels }}"

    - alert: VMOutOfMemory
      expr: (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes < .10)
      for: 20s
      labels:
        severity: critical
      annotations:
        summary: "VM out of memory (instance {{ $labels.instance }})"
        description: "Node memory is filling up (< 10% left)\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"

    - alert: VMHighCpuLoad
      expr: 1 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[1m]))) > .85
      for: 20s
      labels:
        severity: warning
      annotations:
        summary: "VM high CPU load (instance {{ $labels.instance }})"
        description: "CPU load is > 85%\n  VALUE= {{ $value }}\n  LABELS = {{ $labels }}"

    - alert: OpenVPNExporterDown
      expr: up{job="openvpn server"} == 0
      for: 45s
      labels:
        severity: critical
      annotations:
        summary:  "openvpn_exporter on {{ $labels.instance }} is down"
        description: "Prometheus cannot scrape {{ $labels.instance }}:{{ $labels.job }}. Check the systemd unit or Docker container."

    - alert: NoConnectedClients
      expr: absent(openvpn_bytes_received)
      for: 1m
      labels:
        severity: warning
      annotations:
        summary: "No VPN clients connected on {{ $labels.instance }}"
        description: "The exporter sees zero connected clients for the past 1 minute."

EOF
fi

sudo sed -i 's/^\([[:space:]]*\)#\s*- alertmanager:9093/\1- 127.0.0.1:9093/' /etc/prometheus/prometheus.yml
sudo sed -i '/alertrules\.yml/d; /^rule_files:/a\  - alertrules.yml' /etc/prometheus/prometheus.yml
sudo sed -i '/^scrape_configs:/a\
  - job_name: "windows-vm"\
    static_configs:\
      - targets: ["192.168.1.119:9182"]\
\
  - job_name: "docker-swarm-master"\
    static_configs:\
      - targets: ["192.168.1.123:9100"]\
\
  - job_name: "openvpn server"\
    static_configs:\
      - targets: ["3.85.247.98:9176"]\
' /etc/prometheus/prometheus.yml

print_color "green" "check syntax issue"
sudo -u prometheus promtool check config /etc/prometheus/prometheus.yml

print_color "green" "remove unnecessary directory"
rm -rf alertmanager
