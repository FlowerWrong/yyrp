require 'eventmachine'
require 'yyrp/shadowsocks/connection'

module Shadowsocks
  class ServerPool
    attr_accessor :servers
    def initialize(shadowsocks_server)
      @shadowsocks_server = shadowsocks_server
      @servers = {}
    end

    def create(host, port, pass, method)
      signature = EventMachine.start_server(host, port, ShadowsocksConnection, pass, method) do |con|
        con.server = @shadowsocks_server
        con.listen_port = port
      end
      @servers[port] = signature
    end

    def destroy(port)
      signature = @servers[port]
      EventMachine.stop_server(signature) if signature
      @servers[port] = nil
    end
  end
end