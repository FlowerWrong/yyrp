# badvpn

## tun2socks

```bash
# first, compile with https://github.com/ambrop72/badvpn/wiki/Tun2socks and https://code.google.com/archive/p/badvpn/wikis

DNS_SERV="8.8.8.8"
TUN_DEV="tun0"
TUN_IP="10.10.0.1"
TUN_GW="10.10.0.2"
TUN_MASK="255.255.255.0"
TUN_USER="nobody"
SOCKS_PORT="1080"

ORIGINAL_GW="10.0.2.2"

ip tuntap add dev $TUN_DEV mode tun user $TUN_USER
ifconfig $TUN_DEV $TUN_IP netmask $TUN_MASK

badvpn-tun2socks --tundev $TUN_DEV --netif-ipaddr $TUN_GW --netif-netmask $TUN_MASK --socks-server-addr 127.0.0.1:$SOCKS_PORT

ip route replace $SERVER_IP via $ORIGINAL_GW metric 5
ip route del default
ip route add default via $TUN_GW metric 6

curl http://www.ip.cn/

```
