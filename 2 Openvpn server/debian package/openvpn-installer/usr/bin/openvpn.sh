#!/bin/bash
#
# This script automates the installation and configuration of the openvpn server.
# Author: Said Devops
# Email: arabovseyitnazar@gmail.com

######################################
# Print a given message in color
# Arguments:
#   Color.   eg: green, red
######################################
function print_color(){

  case $1 in
    "green") COLOR="\033[0;32m" ;;
    "red") COLOR="\033[0;31m" ;;
    "*") COLOR="\033[0m" ;;
  esac

  echo -e "${COLOR} $2 ${NC}"
}

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

server_name="$1"
client_name="$2"

home="/home/ubuntu/"
openvpn="/etc/openvpn/"
easy_rsa="/etc/openvpn/easy-rsa"
key="/etc/openvpn/easy-rsa/pki/private/${server_name}.key"
dh="/etc/openvpn/easy-rsa/pki/dh.pem"
crt="/etc/openvpn/easy-rsa/pki/issued/${server_name}.crt"
ca_crt="/etc/openvpn/easy-rsa/pki/ca.crt"
ta="/etc/openvpn/easy-rsa/ta.key"
client_key="/etc/openvpn/easy-rsa/pki/private/${client_name}.key"
client_crt="/etc/openvpn/easy-rsa/pki/issued/${client_name}.crt"
client_files="${home}/client_files"
output_ovpn="${client_files}/${client_name}.ovpn"

#-------------VPN CONFIGURATION--------
# Configure OpenVPN

print_color "green" "cd into easy-rsa installation folder"
cd "$easy_rsa"

print_color "green" "Generating openvpn key"
if [ ! -f "$server_name" ]; then
  sudo ./easyrsa gen-req "$server_name" nopass
else
  print_color "green" "File "$server_name" already exists, skipping generate."
fi

print_color "green" "Generating dh file"
if [ ! -f "$dh" ]; then
  sudo ./easyrsa gen-dh
else
  print_color "green" "File "$dh" already exists, skipping generate."
fi

print_color "green" "Signing openvpn certificate"
if [ ! -f "$crt" ]; then
  sudo ./easyrsa sign-req server "$server_name"
else
  print_color "green" "File "$crt" already exists, skipping sign."
fi

sudo cp "$dh" "$ca_crt" "$crt" "$key" "$openvpn"

print_color "green" "Generating secret key"
if [ ! -f "$ta" ]; then
  sudo openvpn --genkey --secret ta.key
else
  print_color "green" "File "$ta" already exists, skipping generate."
fi

print_color "green" "Moving secret key"
sudo mv "$ta" "$openvpn"

print_color "green" "Uncommenting netipv4 line"
sudo sed -i 's/^#\s*\(net\.ipv4\.ip_forward=1\)/\1/' /etc/sysctl.conf
sudo sysctl -p

print_color "green" "Verifying if line was uncommented"
sudo sysctl -w net.ipv4.ip_forward=1

print_color "green" "cd into easy-rsa installation folder"
cd "$easy_rsa"

print_color "green" "Generating openvpn client key and request"
if [ ! -f "$client_key" ] || [ ! -f "$easy_rsa/pki/reqs/${client_name}.req" ]; then
  sudo ./easyrsa gen-req "$client_name" nopass
else
  print_color "green" "File "$client_key" already exists, skipping generate."
fi

print_color "green" "Signing openvpn client certificate"
if [ ! -f "$client_crt" ]; then
  sudo ./easyrsa sign-req client "$client_name"
else
  print_color "green" "File "$client_crt" already exists, skipping sign."
fi

#-------Prepare client files--------

print_color "green" "Creating folder for client files"
mkdir -p "$client_files"
sudo mkdir -p /var/log/openvpn

print_color "green" "Copying CA, TA, client key and certificate to client_files"
sudo cp "$ca_crt" "$openvpn/ta.key" "$client_crt" "$client_key" "$client_files"

print_color "green" "Setting proper permissions on client files"
sudo chmod 644 "$client_files"/*

print_color "green" "checking status of the openvpn server"
sudo systemctl start openvpn@server
sudo systemctl enable openvpn@server
sudo systemctl restart openvpn@server
check_service_status openvpn

# Configure UFW firewall
print_color "green" "configuring ufw firewall..."
sudo sed -i 's/^DEFAULT_FORWARD_POLICY=.*/DEFAULT_FORWARD_POLICY="ACCEPT"/' /etc/default/ufw

# Detect default network interface
EXT_IF=$(ip route get 8.8.8.8 | awk '{for(i=1;i<=NF;i++) if ($i=="dev") print $(i+1)}' | head -n1)

print_color "green" "inserting nat rules..."
if ! sudo grep -q "10.8.0.0/24 -o $EXT_IF -j MASQUERADE" /etc/ufw/before.rules; then
  sudo sed -i '/^# rules.before/a \
*nat\n\
:POSTROUTING ACCEPT [0:0]\n\
-A POSTROUTING -s 10.8.0.0/24 -o $EXT_IF -j MASQUERADE\n\
COMMIT\n' /etc/ufw/before.rules
fi

print_color "green" "inserting openvpn client traffic rules..."
if ! sudo grep -q "tun0 -j ACCEPT" /etc/ufw/before.rules; then
  sudo sed -i '/^# End required lines/a \
# allow OpenVPN client traffic\n\
-A ufw-before-input -i tun0 -j ACCEPT\n\
-A ufw-before-output -o tun0 -j ACCEPT\n\
-A ufw-before-forward -i tun0 -j ACCEPT\n\
-A ufw-before-forward -o tun0 -j ACCEPT\n' /etc/ufw/before.rules
fi

print_color "green" "adding ports in ufw"
sudo ufw allow 1194/udp
sudo ufw allow 22/tcp

print_color "green" "checking status of the ufw"
sudo ufw enable
check_service_status ufw

# 2-nd part client configuration
print_color "green" "inserting necessary files's content into the ovpn file"
cat > "$output_ovpn" <<EOF
client
dev tun
proto udp
remote 3.85.247.98
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
auth SHA512
cipher AES-256-CBC
ignore-unknown-option block-outside-dns
block-outside-dns
verb 3

<ca>
$(cat "$client_files/ca.crt")
</ca>

<cert>
$(awk '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/' "${client_files}/${client_name}.crt")
</cert>

<key>
$(cat "$client_files/${client_name}.key")
</key>

<tls-crypt>
$(cat "$client_files/ta.key")
</tls-crypt>
EOF

print_color "green" "All set"
