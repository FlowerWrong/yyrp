# setup netstack on archlinux

```bash
sudo ip tuntap add user yy mode tun tun0
sudo ip link set tun0 up
sudo ifconfig tun0 192.168.4.1 netmask 255.255.255.0

sudo go run tcpip/sample/tun_tcp_echo/main.go tun0 192.168.4.2 8090
telnet 192.168.4.2 8090
```

```bash
sudo ip tuntap add user yy mode tun tun0
sudo ip link set tun0 up
sudo ifconfig tun0 192.168.4.1 netmask 255.255.255.0

while :; do nc -l -p 1234 | tee output.log; sleep 1; done
sudo go run tcpip/sample/tun_tcp_connect/main.go tun0 192.168.4.2 0 192.168.4.1 1234
```
