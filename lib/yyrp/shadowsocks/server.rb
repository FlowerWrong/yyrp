require 'eventmachine'
require 'active_support/core_ext/hash/keys'
require 'yyrp/shadowsocks/connection'
require 'yyrp/shadowsocks/server_pool'
require 'yyrp/config'

module Yyrp
  class ShadowsocksServer
    attr_accessor :connections, :server_pool

    def initialize
      @connections = []
      init_config
    end

    def init_config
      Yyrp.set_config
    end

    def start
      @server_pool = Shadowsocks::ServerPool.new(self)
    end

    def stop
      EventMachine.stop
    end
  end
end
