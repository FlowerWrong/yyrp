# http://linux.vbird.org/linux_server/0140networkcommand.php#network_setup_ip

# show route table on osx or linux
netstat -rn

# show route
ip route

# openvpn
sudo openvpn --mktun --dev tun2
sudo ip link set tun2 up
sudo ifconfig tun2 192.168.192.100 netmask 255.255.255.0
sudo ip addr add 192.168.192.1/24 dev tun2
sudo ip addr del 192.168.192.1/24 dev tun2
sudo ip route add 192.168.192.0/24 dev tun2

# show route
route -nee
