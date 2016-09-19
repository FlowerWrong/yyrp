$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'yyrp'

# Yyrp.start

EventMachine::run {
  server = Yyrp::Server.new
  Signal.trap('INT') { server.stop }
  Signal.trap('TERM') { server.stop }
  server.start
}