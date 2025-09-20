#!/bin/bash
#
# This script automates the deployment of easy-rsa package
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

# variables for the easy-rsa package
home="/home/ubuntu/easy-rsa"
archive="EasyRSA-3.2.2.tgz"
file="EasyRSA-3.2.2"
url="https://github.com/OpenVPN/easy-rsa/releases/download/v3.2.2/$archive"
path="/etc/openvpn"
dir_name="easy-rsa"
pki="/etc/openvpn/easy-rsa/pki"
ca_crt="/etc/openvpn/easy-rsa/pki/ca.crt"

#---------------------EASY-RSA CONFIGURATION-----------------------
# "Download easy-rsa archive file for linux"
print_color "green" "Downloading archive file using wget tool"
if [ ! -f "$archive" ]; then
  wget "$url"
else
  print_color "green" "File "$archive" already exists, skipping download."
fi

print_color "green" "unarchiving downloaded file"
tar xvf "$archive"

print_color "green" "changing the name of the easy-rsa folder"
mv "$file" "$dir_name"

print_color "green" "removing the archive file"
rm "$archive"

print_color "green" "creating a folder inside /etc/openvpn"
if [ ! -d "$path" ]; then
  sudo mkdir -p "$path"
else
  print_color "green" "Folder "$path" already exists, skipping create."
fi

print_color "green" "moving the easy-rsa folder into the /etc/openvpn/"
sudo mv "$dir_name" "$path"

print_color "green" "cd into easy-rsa installation folder"
cd "$path/$dir_name"

print_color "green" "copying vars example file"
cp vars.example vars

print_color "green" "inserting the necessary information into vars file"
if ! grep -q "Devops and Cloud department" vars; then
  cat <<EOF >> vars

set_var EASYRSA_REQ_COUNTRY     "RU"
set_var EASYRSA_REQ_PROVINCE    "Moscow"
set_var EASYRSA_REQ_CITY        "Moscow"
set_var EASYRSA_REQ_ORG         "INTL IT Organization"
set_var EASYRSA_REQ_EMAIL       "admin@example.net"
set_var EASYRSA_REQ_OU          "Devops and Cloud department"
EOF
fi

vars_results=$(sudo cat vars)

if [[ "$vars_results" == *Devops* ]]
then
  print_color "green" "information data loaded"
else
  print_color "red" "information data not loaded"
  exit 1
fi

print_color "green" "initializing public key infrastructure"
if [ ! -d "$pki" ]; then
  sudo ./easyrsa init-pki
else
  print_color "green" "Folder "$pki" already exists, skipping initialize."
fi

print_color "green" "building certificate authority"
if [ ! -f "$ca_crt" ]; then
  sudo ./easyrsa build-ca
else
  print_color "green" "File "$ca_crt" already exists, skipping build."
fi

print_color "green" "Certificate authority file has been created. See below where it locates:"
print_color "green" "CA certificate: $ca_crt"

print_color "green" "removing unused folder"
if [ -d "$home" ]; then
  rm -rf "$home"
else
  print_color "green" "Folder doesn't exist, skipping deletion."
fi
