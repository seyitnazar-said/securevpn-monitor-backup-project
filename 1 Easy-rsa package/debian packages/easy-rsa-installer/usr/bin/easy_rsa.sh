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
easy_rsa="/etc/openvpn/easy-rsa"
pki="$easy_rsa/pki"
ca_crt="$pki/ca.crt"

#---------------------EASY-RSA CONFIGURATION-----------------------
# "Set necessary info for EASY-RSA"

print_color "green" "cd into easy-rsa installation folder"
cd "$easy_rsa"

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

