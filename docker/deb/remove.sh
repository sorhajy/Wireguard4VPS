echo "#"

echo "# Disabling"
wg-quick down wg0
systemctl stop wg-quick@wg0
systemctl disable wg-quick@wg0

echo "# Removing"
yes | apt autoremove wireguard wireguard-dkms wireguard-tools
#yes | apt autoremove software-properties-common
add-apt-repository --remove ppa:wireguard/wireguard
yes | apt update

echo "# Clearing folder"
rm -rf /etc/wireguard

echo "# Removed"