iptables -t nat -F
iptables -t nat -X
ip6tables -t nat -F
ip6tables -t nat -X
iptables  -F
iptables  -X
ip6tables -F
ip6tables -X
#OpenNIC server, change if dns fails
echo "nameserver 5.135.183.146" > /etc/resolv.conf
service tor stop
service NetworkManager stop
service NetworkManager start
service i2p stop
service i2p start
