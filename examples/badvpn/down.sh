#!/bin/bash
# http://www.yangchuansheng.com/posts/11b0e2ac/

SOCKS_SERVER=$1 # SOCKS 服务器的 IP 地址
SOCKS_PORT=1080 # 本地SOCKS 服务器的端口

# $(ip route | awk '/default/ { print $3 }')
GATEWAY_IP=$2 # 家用网关（路由器）的 IP 地址
TUN_NETWORK_DEV=tun0 # 选一个不冲突的 tun 设备号
TUN_NETWORK_PREFIX=10.0.0 # 选一个不冲突的内网 IP 段的前缀

stop_fwd() {
  ip route del 128.0.0.0/1 via "$TUN_NETWORK_PREFIX.1"
  ip route del 0.0.0.0/1 via "$TUN_NETWORK_PREFIX.1"
  for i in $(cat /home/yy/dev/ruby/yyrp/examples/badvpn/china_ip_list/china_ip_list.txt); do
    ip route del "$i" via "$GATEWAY_IP"
  done

  ipset destroy chnroute

  # ip route del "172.16.39.0/24" via "$GATEWAY_IP"
  ip route del "$SOCKS_SERVER" via "$GATEWAY_IP"
  ip route add default via "$GATEWAY_IP"
  ip link set "$TUN_NETWORK_DEV" down
  ip addr del "$TUN_NETWORK_PREFIX.1/24" dev "$TUN_NETWORK_DEV"
  ip tuntap del dev "$TUN_NETWORK_DEV" mode tun
}

stop_fwd
# trap stop_fwd INT TERM
# wait "$TUN2SOCKS_PID"
