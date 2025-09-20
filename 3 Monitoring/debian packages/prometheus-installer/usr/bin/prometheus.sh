#!/bin/bash
#
# This script automates the deployment of prometheus monitoring server
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

# variables for prometheus server
service="/etc/systemd/system/prometheus.service"

#---------------------PROMETHEUS CONFIGURATION-----------------------
# "User, group and directory management"
print_color "green" "create prometheus user, group and directory and set ownership"

if ! getent group prometheus >/dev/null; then
    sudo groupadd --system prometheus
fi

if ! id -u prometheus >/dev/null 2>&1; then
    sudo useradd --system \
                 --shell /sbin/nologin \
                 --gid prometheus \
                 prometheus
fi

sudo install -d -o prometheus -g prometheus -m 755 /etc/prometheus
sudo install -d -o prometheus -g prometheus -m 755 /var/lib/prometheus

print_color "green" "change ownership"
sudo chown prometheus:prometheus /usr/local/bin/prometheus
sudo chown prometheus:prometheus /usr/local/bin/promtool

print_color "green" "creating a service file"
if [ ! -f "$service" ]; then
  sudo touch "$service"
else
  print_color "green" "File "$service" already exists, skipping create."
fi

print_color "green" "inserting the necessary parameters and values into the service file"
if ! grep -q "web.listen-address=:9090" "$service"; then
  sudo tee -a "$service" >/dev/null <<'EOF'

[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
    --config.file /etc/prometheus/prometheus.yml \
    --storage.tsdb.path /var/lib/prometheus/ \
    --web.console.templates=/etc/prometheus/consoles \
    --web.console.libraries=/etc/prometheus/console_libraries \
    --web.listen-address=:9090 \
    --web.enable-lifecycle \
    --web.enable-admin-api \
    --log.level=info

[Install]
WantedBy=multi-user.target

EOF
fi

print_color "green" "check if data was loaded"
results=$(sudo cat "$service")

if [[ "$results" == *web.listen* ]]
then
  print_color "green" "information data loaded"
else
  print_color "red" "information data not loaded"
  exit 1
fi

print_color "green" "check status of the prometheus server"
sudo systemctl daemon-reload
sudo systemctl start prometheus.service
sudo systemctl enable prometheus.service
sudo systemctl restart prometheus.service
check_service_status prometheus

print_color "green" "check syntax issue in config file"
sudo -u prometheus promtool check config /etc/prometheus/prometheus.yml
