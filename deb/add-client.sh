#!/bin/bash

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

cd /etc/wireguard/ || exit 1

read -r DNS < ./dns.var
read -r ENDPOINT < ./endpoint.var
read -r VPN_SUBNET < ./vpn_subnet.var
PRESHARED_KEY="_preshared.key"
PRIV_KEY="_private.key"
PUB_KEY="_public.key"
ALLOWED_IP="0.0.0.0/0, ::/0"

# Go to the wireguard directory and create a directory structure in which we will store client configuration files
mkdir -p ./clients
cd ./clients || exit 1
mkdir "./$USERNAME"
cd "./$USERNAME" || exit 1
umask 077

CLIENT_PRESHARED_KEY=$( wg genpsk )
CLIENT_PRIVKEY=$( wg genkey )
CLIENT_PUBLIC_KEY=$( echo "$CLIENT_PRIVKEY" | wg pubkey )

echo "$CLIENT_PRESHARED_KEY" > ./"$USERNAME$PRESHARED_KEY"
echo "$CLIENT_PRIVKEY" > ./"$USERNAME$PRIV_KEY"
echo "$CLIENT_PUBLIC_KEY" > ./"$USERNAME$PUB_KEY"

read -r SERVER_PUBLIC_KEY < /etc/wireguard/server_public.key

# We get the following client IP address
read -r OCTET_IP < /etc/wireguard/last_used_ip.var
OCTET_IP=$(($OCTET_IP+1))
echo $OCTET_IP > /etc/wireguard/last_used_ip.var

CLIENT_IP="$VPN_SUBNET$OCTET_IP/32"

# Create a blank configuration file client 
cat > "/etc/wireguard/clients/$USERNAME/$USERNAME.conf" << EOF
[Interface]
PrivateKey = $CLIENT_PRIVKEY
Address = $CLIENT_IP
DNS = $DNS


[Peer]
PublicKey = $SERVER_PUBLIC_KEY
PresharedKey = $CLIENT_PRESHARED_KEY
AllowedIPs = $ALLOWED_IP
Endpoint = $ENDPOINT
PersistentKeepalive=60
EOF

# Add new client data to the Wireguard configuration file
cat >> /etc/wireguard/wg0.conf << EOF
# $USERNAME
[Peer]
AllowedIPs = $CLIENT_IP
PresharedKey = $CLIENT_PRESHARED_KEY
PublicKey = $CLIENT_PUBLIC_KEY
EOF

# Restart Wireguard
systemctl stop wg-quick@wg0
systemctl start wg-quick@wg0

# Show QR config to display
qrencode -t ansiutf8 < "./$USERNAME.conf"

# Show config file
echo "# Display $USERNAME.conf"
cat "./$USERNAME.conf"

# Save QR config to png file
#qrencode -t png -o ./$USERNAME.png < ./$USERNAME.conf
