
sudo ifconfig utun1 inet 10.0.0.1 10.0.0.2 netmask 255.255.255.0

# osx route
sudo route add -net 0.0.0.0 172.30.20.1 -netmask 128.0.0.0
sudo route add -net 128.0.0.0 172.30.20.1 -netmask 128.0.0.0

my_ss_server=x.x.x.x
orig_gw=$(netstat -nr | grep --color=never '^default' | grep -v 'utun' | sed 's/default *\([0-9\.]*\) .*/\1/' | head -1)
sudo route add -net $my_ss_server $origin_gw
