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
#   Service.    eg: prometheus, alertmanager, node_exporter, openvpn_exporter
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

# variables for openvpn_exporter service
package="/home/ubuntu/openvpn_exporter"
openvpn_exporter_bin="/usr/local/bin/openvpn_exporter"
service="/etc/systemd/system/openvpn_exporter.service"
log="/var/log/openvpn/"
status_log="/var/log/openvpn/openvpn-status.log"

#---------------------OPENVPN-EXPORTER CONFIGURATION-----------------------
# "User, group and directory management"
print_color "green" "create openvpn_exporter user, group and directory and set ownership"

if ! getent group openvpn_exporter >/dev/null; then
    sudo groupadd -f openvpn_exporter
fi

if ! id -u openvpn_exporter >/dev/null 2>&1; then
    sudo useradd --no-create-home \
                 --shell /bin/false \
                 --gid openvpn_exporter \
                 openvpn_exporter
fi

sudo install -d -o openvpn_exporter -g openvpn_exporter -m 755 /etc/openvpn_exporter

# "Install openvpn_exporter, change ownership and create a service file"
print_color "green" "move a binary file"
sudo mv "$package" "$openvpn_exporter_bin"

print_color "green" "change ownership"
sudo chown openvpn_exporter:openvpn_exporter "$openvpn_exporter_bin"

print_color "green" "creating a service file"
if [ ! -f "$service" ]; then
  sudo touch "$service"
else
  print_color "green" "File "$service" already exists, skipping create."
fi

print_color "green" "inserting openvpn exporter values into the service file"
if ! grep -q "openvpn_exporter" "$service"; then
  sudo tee -a "$service" >/dev/null <<'EOF'
[Unit]
Description=Openvpn Exporter
Documentation=https://github.com/patrickjahns/openvpn_exporter
Wants=network-online.target
After=network-online.target

[Service]
User=openvpn_exporter
Group=openvpn_exporter
Type=simple
Restart=on-failure
ExecStart=/usr/local/bin/openvpn_exporter --status-file /var/log/openvpn/openvpn-status.log --web.listen-address=0.0.0.0:9176


[Install]
WantedBy=multi-user.target

EOF
fi

print_color "green" "change mode of the service"
sudo chmod 664 "$service"

print_color "green" "check if data was loaded"
results=$(sudo cat "$service")

if [[ "$results" == *openvpn* ]]
then
  print_color "green" "information data loaded"
else
  print_color "red" "information data not loaded"
  exit 1
fi

print_color "green" "check status of the openvpn_exporter service"
sudo systemctl daemon-reload
sudo systemctl start openvpn_exporter.service
sudo systemctl enable openvpn_exporter.service
sudo systemctl restart openvpn_exporter.service
check_service_status openvpn_exporter

print_color "green" "change ownership, mode of the openvpn log files"
sudo chown -R openvpn_exporter:openvpn_exporter "$log"
sudo chmod 655 "$status_log"
