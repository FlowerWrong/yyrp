$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'yyrp'

EventMachine::run {
  server = Yyrp::ShadowsocksServer.new
  Signal.trap('INT') { server.stop }
  Signal.trap('TERM') { server.stop }
  server.start
}
