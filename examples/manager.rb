$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'yyrp'
require 'socket'
require 'yyrp/shadowsocks/models'
require 'json'

Yyrp::ShadowsocksServer.new
$last_stat = nil

# ./ss-manager --manager-address 127.0.0.1:6001 -c ./multi.json -v
# for https://github.com/shadowsocks/shadowsocks-libev
# ./configure --prefix=./ --with-openssl=/usr/local/opt/openssl --disable-documentation
udp_manager_socket = UDPSocket.new
loop {
  udp_manager_socket.send 'ping', 0, '127.0.0.1', 6001
  msg, addr = udp_manager_socket.recvfrom(1024)
  Yyrp.logger.info "msg: #{msg}, addr:#{addr}"
  if msg.start_with?('stat: ')
    stat = JSON.parse(msg[6..-1])
    User.where(enable: true).each do |user|
      if (user.expire_time > Time.now) && (user.flow_up + user.flow_down < user.total_flow)
        if stat["#{user.port}"].nil?
          Yyrp.logger.info "user #{user.id} port: #{user.port}, method: #{user.method} to be start"
          json_hash = {"server_port": user.port, "password": user.sspass}
          udp_manager_socket.send "add: #{json_hash.to_json}", 0, '127.0.0.1', 6001
        else
          current_flow = stat["#{user.port}"]
          last_flow = $last_stat["#{user.port}"].nil? ? 0 : $last_stat["#{user.port}"]
          user.update(flow_up: (user.flow_up + (current_flow - last_flow)))
        end
      else
        unless stat["#{user.port}"].nil?
          Yyrp.logger.info "user #{user.id} port: #{user.port}, method: #{user.method} to be stop"
          json_hash = {"server_port": user.port}
          udp_manager_socket.send "remove: #{json_hash.to_json}", 0, '127.0.0.1', 6001
        end
      end
    end
    $last_stat = stat
  end

  sleep 10
}
