# Make sure only root can run this script
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

iptables -t nat -F
iptables -t nat -X
ip6tables -t nat -F
ip6tables -t nat -X
iptables  -F
iptables  -X
ip6tables -F
ip6tables -X
#OpenNIC server, change if dns fails
echo "nameserver 88.175.188.50" > /etc/resolv.conf
service tor stop
service NetworkManager stop
service NetworkManager start
service i2p stop
service i2p start
