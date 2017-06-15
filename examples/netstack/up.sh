#!/bin/bash

# $(ip route | awk '/default/ { print $3 }')
GATEWAY_IP=$(ip route | awk '/default/ { print $3 }') # 家用网关（路由器）的 IP 地址
TUN_NETWORK_DEV=tun5 # 选一个不冲突的 tun 设备号
TUN_NETWORK_PREFIX=172.0.0 # 选一个不冲突的内网 IP 段的前缀

start_fwd() {
  ip tuntap del dev "$TUN_NETWORK_DEV" mode tun
  # 添加虚拟网卡
  ip tuntap add dev "$TUN_NETWORK_DEV" mode tun
  # 给虚拟网卡绑定IP地址
  ip addr add "$TUN_NETWORK_PREFIX.1/24" dev "$TUN_NETWORK_DEV"
  # 启动虚拟网卡
  ip link set "$TUN_NETWORK_DEV" up
  ip route del default via "$GATEWAY_IP"
  # 将默认网关设为虚拟网卡的IP地址
  # ip route add 0.0.0.0/1 via "$TUN_NETWORK_PREFIX.1"
  # ip route add 128.0.0.0/1 via "$TUN_NETWORK_PREFIX.1"
}

start_fwd
