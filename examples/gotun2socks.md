# [gotun2socks](https://github.com/yinghuocho/gotun2socks)

## OSX

```bash
# 1. start shadowsocks server on vps with udp relay
ss-server -u
# 2. start shadowsocks client on your computer with udp relay
ss-local -u

# 3. start tun2socks with socks proxy
sudo ./gotun2socks --local-socks-addr 127.0.0.1:1080

# osx route
sudo route add -net 0.0.0.0 10.0.0.1 -netmask 128.0.0.0
sudo route add -net 128.0.0.0 10.0.0.1 -netmask 128.0.0.0

my_ss_server=x.x.x.x
orig_gw=$(netstat -nr | grep --color=never '^default' | grep -v 'utun' | sed 's/default *\([0-9\.]*\) .*/\1/' | head -1)
sudo route add -host $my_ss_server $origin_gw
```

## BUG

* ERROR: accept: Too many open files => `ulimit -a`
