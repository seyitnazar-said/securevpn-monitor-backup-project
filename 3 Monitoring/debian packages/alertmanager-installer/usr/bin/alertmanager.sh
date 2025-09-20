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
service="/etc/systemd/system/alertmanager.service"

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

print_color "green" "change ownership"
sudo chown alertmanager:alertmanager /usr/local/bin/alertmanager
sudo chown alertmanager:alertmanager /usr/local/bin/amtool
sudo chown alertmanager:alertmanager /etc/alertmanager/alertmanager.yml

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

print_color "green" "check syntax issue"
sudo -u prometheus promtool check config /etc/prometheus/prometheus.yml

print_color "green" "restart prometheus server"
sudo systemctl restart prometheus.service
