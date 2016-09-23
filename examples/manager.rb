require 'socket'

# ./ss-manager --manager-address 127.0.0.1:6001 -c ./multi.json -v
# for https://github.com/shadowsocks/shadowsocks-libev
# ./configure --prefix=./ --with-openssl=/usr/local/opt/openssl --disable-documentation
udp_manager_socket = UDPSocket.new
loop {
  udp_manager_socket.send 'ping', 0, '127.0.0.1', 6001
  msg, addr = udp_manager_socket.recvfrom(1024)
  p msg, addr
  sleep 10
}
