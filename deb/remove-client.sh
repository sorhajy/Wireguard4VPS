#!/bin/bash

set -Eeo pipefail

# We read from the input parameter the name of the client
if [ -z "$1" ]
  then 
    read -p "Enter VPN user name: " USERNAME
    if [ -z "$USERNAME" ]
      then
      echo "[#]Empty VPN user name. Exit"
      exit 1;
    fi
  else USERNAME=$1
fi

if [ ! -d "/etc/wireguard/clients/$USERNAME" ];
then
    exit 1
fi

mv "/etc/wireguard/clients/$USERNAME" "/etc/wireguard/clients/disabled_$(date +"%Y-%m-%d-%H-%M-%S")_$USERNAME"

sed -i "/# $USERNAME/,+4 d" /etc/wireguard/wg0.conf

# Restart Wireguard
systemctl stop wg-quick@wg0
systemctl start wg-quick@wg0
