require 'eventmachine'
require 'active_support/core_ext/hash/keys'
require 'yyrp/shadowsocks/connection'
require 'yyrp/shadowsocks/models'
require 'yyrp/shadowsocks/server_pool'
require 'yyrp/config'

module Yyrp
  class ShadowsocksServer
    attr_accessor :connections, :server_pool

    def initialize
      @connections = []
      Yyrp.set_config

      ActiveRecord::Base.establish_connection(
        adapter:  'mysql2',
        host:     Yyrp.config.servers['mysql']['host'],
        username: Yyrp.config.servers['mysql']['username'],
        password: Yyrp.config.servers['mysql']['password'],
        database: Yyrp.config.servers['mysql']['database']
      )
      ActiveRecord::Base.default_timezone = :local
    end

    def start
      @server_pool = Shadowsocks::ServerPool.new(self)
      dynamic_server_timer
    end

    def stop
      EventMachine.stop
    end

    def dynamic_server_timer
      EM.add_periodic_timer(3) {
        User.where(enable: true).each do |user|
          if (user.expire_time > Time.now) && (user.flow_up + user.flow_down < user.total_flow)
            if @server_pool.servers == {} || (@server_pool.servers != {} && @server_pool.servers[user.port].nil?)
              Yyrp.logger.info "user #{user.id} port: #{user.port}, method: #{user.method} to be start"
              @server_pool.create('0.0.0.0', user.port, user.sspass, user.method)
            end
          else
            if @server_pool.servers != {} && !@server_pool.servers[user.port].nil?
              Yyrp.logger.info "user #{user.id} port: #{user.port}, method: #{user.method} to be stop"
              @server_pool.destroy(user.port)
            end
          end
        end
      }
    end
  end
end
