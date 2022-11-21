#! /bin/bash
set -euo pipefail

if [[ $(id -u) -ne 0 ]]; then
	echo "Please run the script as root or use sudo"
	exit 1
fi

nic=`ip route | grep default | sed -n '1p' | awk '{print $5}'`
gateway=`ip route | grep default | sed -n '1p' | awk '{print $3}'`
subnet=`ip addr show dev "$nic" | grep -w inet | awk '{print $2}'`

brctl addbr br0
brctl addif br0 "$nic"
ip link set dev br0 up
ip addr add "$subnet" dev br0
ip route add default via "$gateway" dev br0
sleep 1
ip addr flush dev "$nic"
ip link set dev "$nic" promisc on

ip link add dev veth0 type veth peer name veth1
ip link set dev veth0 up
ip link set dev veth1 up
brctl addif br0 veth1

docker network -d macvlan --subnet="$subnet" --gateway="$gateway" -o parent=veth0 macnet
