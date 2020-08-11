echo "# Removing"

systemctl stop wg-quick@wg0
systemctl disable wg-quick@wg0
wg-quick down wg0

rm -rf /etc/wireguard

echo "# Removed"
