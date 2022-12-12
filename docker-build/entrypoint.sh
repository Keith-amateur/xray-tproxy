#! /bin/sh
set -eu

ip route add local 0.0.0.0/0 dev lo table 100
ip rule add fwmark 1 table 100

ipset -N privaddrV4 hash:net
ipset -A -exist privaddrV4 0.0.0.0/8
ipset -A -exist privaddrV4 10.0.0.0/8
ipset -A -exist privaddrV4 100.64.0.0/10
ipset -A -exist privaddrV4 127.0.0.0/8
ipset -A -exist privaddrV4 169.254.0.0/16
ipset -A -exist privaddrV4 172.16.0.0/12
ipset -A -exist privaddrV4 192.0.0.0/24
ipset -A -exist privaddrV4 192.0.2.0/24
ipset -A -exist privaddrV4 192.88.99.0/24
ipset -A -exist privaddrV4 192.168.0.0/16
ipset -A -exist privaddrV4 192.18.0.0/15
ipset -A -exist privaddrV4 192.51.100.0/24
ipset -A -exist privaddrV4 203.0.113.0/24
ipset -A -exist privaddrV4 224.0.0.0/4
ipset -A -exist privaddrV4 240.0.0.0/4
ipset -A -exist privaddrV4 255.255.255.255/32

iptables -t mangle -N XRAY
iptables -t mangle -A XRAY -m set --match-set privaddrV4 dst -j RETURN
iptables -t mangle -A XRAY -p tcp -j TPROXY --on-ip 127.0.0.1 --on-port 12345 --tproxy-mark 1
iptables -t mangle -A XRAY -p udp -j TPROXY --on-ip 127.0.0.1 --on-port 12345 --tproxy-mark 1
iptables -t mangle -A PREROUTING -j XRAY

iptables -t mangle -N DIVERT
iptables -t mangle -A DIVERT -j MARK --set-mark 1
iptables -t mangle -A DIVERT -j ACCEPT
iptables -t mangle -I PREROUTING -p tcp -m socket -j DIVERT


sed '43r /etc/xray/outbound.json' /tproxy-example.json >/etc/xray/tproxy.json
/usr/bin/xray -config /etc/xray/"$1"
