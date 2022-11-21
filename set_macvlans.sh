#! /bin/bash
set -euo pipefail

if [[ $(id -u) -ne 0 ]]; then
	echo "Please run the script as root or use sudo"
	exit 1
fi

nic=`ip route | grep default | sed -n '1p' | awk '{print $5}'`
gateway=`ip route | grep default | sed -n '1p' | awk '{print $3}'`
subnet=`ip addr show dev "$nic" | grep -w inet | awk '{print $2}'`
#ipaddr=${subnet%/*}

ip link set dev "$nic" promisc on

docker network create -d macvlan --subnet="$subnet" --gateway="$gateway" -o parent="$nic" mac_proxy

ip link add link "$nic" dev mac_net type macvlan mode bridge
sleep 1
ip addr flush dev "$nic"
ip addr add "$subnet" dev mac_net
ip link set dev mac_net up
ip route add default via "$gateway" dev mac_net metric 100
