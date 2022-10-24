FROM golang:bullseye as builder
WORKDIR /build
RUN git clone https://github.com/XTLS/Xray-core.git && cd Xray-core && \
		go build -o /build/xray -trimpath -ldflags '-s -w -buildid=' /build/Xray-core/main


FROM alpine:latest
ENV SUBNET=192.168.0.0/16
COPY entrypoint.sh tproxy-example.json /
COPY --from=builder /build/xray /usr/bin/
RUN mkdir /usr/local/share/xray && \
		wget https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat -O /usr/local/share/xray/geoip.dat && \
		wget https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat -O /usr/local/share/xray/geosite.dat && \
		apk update && apk add --no-cache iptables && \
		mkdir /lib64 && ln -s /lib/libc.musl-x86_64.so.1 /lib64/ld-linux-x86-64.so.2 && \
		chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["tproxy.json"]
		

