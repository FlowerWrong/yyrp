$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'yyrp'
require 'yyrp/dns/server'

server = Dns::Server.new(listen: [[:udp, '127.0.0.1', 5354]])
server.run

sleep
