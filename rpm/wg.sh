#!/bin/bash

get_message () {
    echo -en "\n \033[33m $1 \033[0m  \n";
}

get_message "WireGuard CLI: 
1) Initial
2) Install
3) Reset
4) Add user";

case $inputCase in
1) 
#initial
echo "# Installing Wireguard"
./remove.sh
./install.sh
./add-client.sh
echo "# Wireguard installed" 
;;
    
2)  
#install
yum update -y -y
yum install epel-release -y 
curl -Lo /etc/yum.repos.d/wireguard.repo https://copr.fedorainfracloud.org/coprs/jdoss/wireguard/repo/epel-7/jdoss-wireguard-epel-7.repo 
yum install wireguard-dkms wireguard-tools -y -y 

mkdir /etc/wireguard #&& cd /etc/wireguard
#bash -c 'umask 077; touch wg0.conf'
ip link add dev wg0 type wireguard
#ip addr add dev wg0 10.50.0.1/24
#wg-quick save wg0

NET_FORWARD="net.ipv4.ip_forward=1"
sysctl -w  ${NET_FORWARD}
sed -i "s:#${NET_FORWARD}:${NET_FORWARD}:" /etc/sysctl.conf
cd /etc/wireguard
umask 077
SERVER_PRIVKEY=$( wg genkey )
SERVER_PUBKEY=$( echo $SERVER_PRIVKEY | wg pubkey )
echo $SERVER_PUBKEY > ./server_public.key
echo $SERVER_PRIVKEY > ./server_private.key
read -p "Enter the endpoint (external ip and port) in format [ipv4:port] (e.g. 4.3.2.1:54321):" ENDPOINT
if [ -z $ENDPOINT ]
then
echo "[#]Empty endpoint. Exit"
exit 1;
fi
echo $ENDPOINT > ./endpoint.var
if [ -z "$1" ]
  then 
    read -p "Enter the server address in the VPN subnet (CIDR format), [ENTER] set to default: 10.50.0.1: " SERVER_IP
    if [ -z $SERVER_IP ]
      then SERVER_IP="10.50.0.1"
    fi
  else SERVER_IP=$1
fi
echo $SERVER_IP | grep -o -E '([0-9]+\.){3}' > ./vpn_subnet.var
read -p "Enter the ip address of the server DNS (CIDR format), [ENTER] set to default: 1.1.1.1): " DNS
if [ -z $DNS ]
then DNS="1.1.1.1"
fi
echo $DNS > ./dns.var
echo 1 > ./last_used_ip.var
read -p "Enter the name of the WAN network interface ([ENTER] set to default: eth0): " WAN_INTERFACE_NAME
if [ -z $WAN_INTERFACE_NAME ]
then
  WAN_INTERFACE_NAME="eth0"
fi
echo $WAN_INTERFACE_NAME > ./wan_interface_name.var
cat ./endpoint.var | sed -e "s/:/ /" | while read SERVER_EXTERNAL_IP SERVER_EXTERNAL_PORT
do
cat > ./wg0.conf.def << EOF
[Interface]
Address = $SERVER_IP
SaveConfig = false
PrivateKey = $SERVER_PRIVKEY
ListenPort = $SERVER_EXTERNAL_PORT
PostUp   = iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -o $WAN_INTERFACE_NAME -j MASQUERADE;
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -o $WAN_INTERFACE_NAME -j MASQUERADE;
EOF
done
cp -f ./wg0.conf.def ./wg0.conf
wg-quick up wg0
;;

3)
#add user
if [ -z "$1" ]
  then 
    read -p "Enter VPN user name: " USERNAME
    if [ -z $USERNAME ]
      then
      echo "[#]Empty VPN user name. Exit"
      exit 1;
    fi
  else USERNAME=$1
fi
cd /etc/wireguard/
read DNS < ./dns.var
read ENDPOINT < ./endpoint.var
read VPN_SUBNET < ./vpn_subnet.var
PRESHARED_KEY="_preshared.key"
PRIV_KEY="_private.key"
PUB_KEY="_public.key"
ALLOWED_IP="0.0.0.0/0, ::/0"
mkdir -p ./clients
cd ./clients
mkdir ./$USERNAME
cd ./$USERNAME
umask 077
CLIENT_PRESHARED_KEY=$( wg genpsk )
CLIENT_PRIVKEY=$( wg genkey )
CLIENT_PUBLIC_KEY=$( echo $CLIENT_PRIVKEY | wg pubkey )
read SERVER_PUBLIC_KEY < /etc/wireguard/server_public.key
read OCTET_IP < /etc/wireguard/last_used_ip.var
OCTET_IP=$(($OCTET_IP+1))
echo $OCTET_IP > /etc/wireguard/last_used_ip.var
CLIENT_IP="$VPN_SUBNET$OCTET_IP/32"
cat > /etc/wireguard/clients/$USERNAME/$USERNAME.conf << EOF
[Interface]
PrivateKey = $CLIENT_PRIVKEY
Address = $CLIENT_IP
DNS = $DNS

[Peer]
PublicKey = $SERVER_PUBLIC_KEY
PresharedKey = $CLIENT_PRESHARED_KEY
AllowedIPs = $ALLOWED_IP
Endpoint = $ENDPOINT
PersistentKeepalive=25
EOF
cat >> /etc/wireguard/wg0.conf << EOF

[Peer]
PublicKey = $CLIENT_PUBLIC_KEY
PresharedKey = $CLIENT_PRESHARED_KEY
AllowedIPs = $CLIENT_IP
EOF

wg-quick down wg0
wg-quick up wg0

qrencode -t ansiutf8 < ./$USERNAME.conf

echo "# Display $USERNAME.conf"
cat ./$USERNAME.conf

#qrencode -t png -o ./$USERNAME.png < ./$USERNAME.conf
;;
    
*) ;;
esac    

