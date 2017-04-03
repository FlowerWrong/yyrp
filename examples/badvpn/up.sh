#!/bin/bash
# http://www.yangchuansheng.com/posts/11b0e2ac/

SOCKS_SERVER=$1 # SOCKS 服务器的 IP 地址
SOCKS_PORT=1080 # 本地SOCKS 服务器的端口

# $(ip route | awk '/default/ { print $3 }')
GATEWAY_IP=$2 # 家用网关（路由器）的 IP 地址
TUN_NETWORK_DEV=tun0 # 选一个不冲突的 tun 设备号
TUN_NETWORK_PREFIX=10.0.0 # 选一个不冲突的内网 IP 段的前缀

start_fwd() {
  ip tuntap del dev "$TUN_NETWORK_DEV" mode tun
  # 添加虚拟网卡
  ip tuntap add dev "$TUN_NETWORK_DEV" mode tun
  # 给虚拟网卡绑定IP地址
  ip addr add "$TUN_NETWORK_PREFIX.1/24" dev "$TUN_NETWORK_DEV"
  # 启动虚拟网卡
  ip link set "$TUN_NETWORK_DEV" up
  ip route del default via "$GATEWAY_IP"
  ip route add "$SOCKS_SERVER" via "$GATEWAY_IP"
  # DNS
  # 特殊ip段走家用网关（路由器）的 IP 地址（如局域网联机）
  # ip route add "172.16.39.0/24" via "$GATEWAY_IP"
  # 国内网段走家用网关（路由器）的 IP 地址
  for i in $(cat /home/yy/dev/ruby/yyrp/examples/badvpn/cn_rules.conf); do
    ip route add "$i" via "$GATEWAY_IP"
  done
  # 将默认网关设为虚拟网卡的IP地址
  ip route add 0.0.0.0/1 via "$TUN_NETWORK_PREFIX.1"
  ip route add 128.0.0.0/1 via "$TUN_NETWORK_PREFIX.1"
  # 将socks5转为vpn
  /home/yy/dev/c/badvpn/badvpn-build/tun2socks/badvpn-tun2socks --tundev "$TUN_NETWORK_DEV" --netif-ipaddr "$TUN_NETWORK_PREFIX.2" --netif-netmask 255.255.255.0 --socks-server-addr "127.0.0.1:$SOCKS_PORT"
  # TUN2SOCKS_PID="$!"
}

start_fwd
# trap stop_fwd INT TERM
# wait "$TUN2SOCKS_PID"
