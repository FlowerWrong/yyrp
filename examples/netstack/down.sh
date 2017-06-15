#!/bin/bash

# $(ip route | awk '/default/ { print $3 }')
GATEWAY_IP=$1 # 家用网关（路由器）的 IP 地址
TUN_NETWORK_DEV=tun5 # 选一个不冲突的 tun 设备号
TUN_NETWORK_PREFIX=172.0.0 # 选一个不冲突的内网 IP 段的前缀

stop_fwd() {
  ip route del 128.0.0.0/1 via "$TUN_NETWORK_PREFIX.1"
  ip route del 0.0.0.0/1 via "$TUN_NETWORK_PREFIX.1"

  ip route add default via "$GATEWAY_IP"
  ip link set "$TUN_NETWORK_DEV" down
  ip addr del "$TUN_NETWORK_PREFIX.1/24" dev "$TUN_NETWORK_DEV"
  ip tuntap del dev "$TUN_NETWORK_DEV" mode tun
}

stop_fwd
