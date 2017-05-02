#rc-service iptables stop
#rc-service ip6tables stop
#rc-service iptables start
#rc-service ip6tables start
iptables -t nat -F
iptables -t nat -X
ip6tables -t nat -F
ip6tables -t nat -X
iptables  -F
iptables  -X
ip6tables -F
ip6tables -X
echo "nameserver ::1, 127.0.0.1" > /etc/resolv.conf
iptables -t nat -A OUTPUT -p TCP --dport 53 -j DNAT --to-destination 127.0.0.1:9053
iptables -t nat -A OUTPUT -p UDP --dport 53 -j DNAT --to-destination 127.0.0.1:9053
iptables -t nat -A OUTPUT -p TCP -m owner ! --uid-owner tor -j DNAT --to-destination 127.0.0.1:9040 
ip6tables -t nat -A OUTPUT -p TCP --dport 53 -j DNAT --to-destination [::1]:9054
ip6tables -t nat -A OUTPUT -p UDP --dport 53 -j DNAT --to-destination [::1]:9054
ip6tables -t nat -A OUTPUT -p TCP -m owner ! --uid-owner tor -j DNAT --to-destination [::1]:9041
service tor stop
service NetworkManager stop
service tor start
service NetworkManager start
