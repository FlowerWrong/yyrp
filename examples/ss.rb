$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'yyrp'
require 'yyrp/shadowsocks/server'

EventMachine::run {
  Signal.trap('INT') { EventMachine.stop }
  Signal.trap('TERM') { EventMachine.stop }
  ss_host = '0.0.0.0'
  ss_port = 6666
  EventMachine::start_server ss_host, ss_port, ShadowsocksServer, 'liveneeq.com', 'aes-256-cfb', true
  puts "running shadowsocks server on #{ss_port}"
}