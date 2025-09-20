#!/bin/bash
#
# This script automates the deployment of node-exporter for the prometheus monitoring server
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
#   Service.    eg: prometheus, alertmanager, node_exporter
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


# variables for node_exporter service
service="/etc/systemd/system/node_exporter.service"

#---------------------NODE-EXPORTER CONFIGURATION-----------------------
# "User, group and directory management"
print_color "green" "create node_exporter user, group and directory and set ownership"

if ! getent group node_exporter >/dev/null; then
    sudo groupadd -f node_exporter
fi

if ! id -u node_exporter >/dev/null 2>&1; then
    sudo useradd --no-create-home \
                 --shell /bin/false \
                 --gid node_exporter \
                 node_exporter
fi

sudo install -d -o node_exporter -g node_exporter -m 755 /etc/node_exporter

print_color "green" "change ownership"
sudo chown node_exporter:node_exporter /usr/local/bin/node_exporter

print_color "green" "creating a service file"
if [ ! -f "$service" ]; then
  sudo touch "$service"
else
  print_color "green" "File "$service" already exists, skipping create."
fi

print_color "green" "inserting the necessary parameters and values into the service file"
if ! grep -q "node_exporter" "$service"; then
  sudo tee -a "$service" >/dev/null <<'EOF'
[Unit]
Description=Node Exporter
Documentation=https://prometheus.io/docs/guides/node-exporter/
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
Restart=on-failure
ExecStart=/usr/local/bin/node_exporter \
  --web.listen-address=:9100

[Install]
WantedBy=multi-user.target

EOF
fi

print_color "green" "change mode of the service"
sudo chmod 664 "$service"

print_color "green" "check if data was loaded"
results=$(sudo cat "$service")

if [[ "$results" == *node_exporter* ]]
then
  print_color "green" "information data loaded"
else
  print_color "red" "information data not loaded"
  exit 1
fi

print_color "green" "check status of the node_exporter service"
sudo systemctl daemon-reload
sudo systemctl start node_exporter
sudo systemctl enable node_exporter.service
sudo systemctl restart node_exporter
check_service_status node_exporter
