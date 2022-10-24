# docker旁路由 实现透明代理
## Requirements
- /etc/xray/outbound.json  
- macvlan network 
## Example
1. outbound.json  
具体配置方法, 请参考 [Xray-examples](https://github.com/XTLS/Xray-examples) 服务器端配置文件中的outbounds字段的内容
```json
    {
        "tag": "proxy",
	    "protocol": "shadowsocks", # shadowsocks, vless, vmess, trojan whatever you want
	    "settings": {
		    "servers": [
			    {
				    "address": "{{ ip address }}",
				    "port": "{{ port }}",
				    "method": "{{ encryption method }}",
				    "password": "{{ password }}"
		    	}
		    ]
	    },
	    "streamSettings": {
		    "network": "tcp"
	    }
    },
-------------------------------------------------------------------------------------------------
注意事项:
1. json文件存放于/etc/xray目录下
2. json文件名必须为outbound.json
3. 字段"tag"是必要的，且其值必须为"proxy"
4. 文件结尾需要有','
```
2. macvlan network
```bash
docker network create -d macvlan --subnet=192.168.1.0/24 --gateway=192.168.1.1 -o parent=eth0 macnet
-------------------------------------------------------------------------------------------------
注意事项:
1. subnet gateway parent网卡 请根据实际的网络情况更改
2. parent网卡 eth0 必须支持且开启promisc混杂模式 # ip link set dev eth0 promisc on
```

## Run
```bash
docker pull keithdockerhub/xray-tproxy:latest
docker run -d -v /etc/xray:/etc/xray --network macnet --ip 192.168.1.254 --privileged keithdockerhub/xray-tproxy:latest
-------------------------------------------------------------------------------------------------
注意事项:
ip 是未被局域网其他主机正在使用的，最好为dhcp地址范围外的ip.
```
容器正常运行后，对于局域网的其他主机将网关地址改为容器的ip(上例: 192.168.1.254)即可实现透明代理。也可以直接使用socks5代理(socks5://192.168.1.254:10808)或http代理(http://192.168.1.254:10809)  
然而容器的宿主机无法使用代理，因为在macvlan的bridge模式下，父接口无法访问子接口。  

---
## 通过虚拟网卡bridge与veth协助宿主机使用代理
- bridge 网卡
```bash
# 下述仅为示例，实际情况请使用NetworkManger、 netctl或修改linux网络配置文件来构建bridge网卡，并使用dhcp
brctl addbr br0
ip link set dev br0 up
brctl addif br0 eth0
ip addr flush dev eth0
ip link set dev eth0 promisc on
ip addr add 192.168.1.100/24 dev br0
ip route add default via 192.168.1.1 dev br0 metric 100
```
- veth 网卡
```bash
ip link add dev veth0 type veth peer name veth1
ip link set dev veth0 up
ip link set dev veth1 up
brctl addif br0 veth1
```

完成上述操作后，可以认为当前宿主机上有两张在同一链路上的独立网卡: br0 与 veth0. 
- br0作为上网的网卡
- veth0作为macvlan网络的父接口

```bash
docker network create -d macvlan --subnet=192.168.1.0/24 --gateway=192.168.1.1 -o parent=veth0 macnet
docker run -d -v /etc/xray:/etc/xray --network macnet --ip 192.168.1.254 --privileged keithdockerhub/xray-tproxy:latest
# 加入新的默认路由(修改网关), 即可实现透明代理
ip route add default via 192.168.1.254 dev br0
```
## References
1. [Project X](https://xtls.github.io/)
2. [Xray-core](https://github.com/XTLS/Xray-core)
3. [Xray-example](https://github.com/XTLS/Xray-examples) 
