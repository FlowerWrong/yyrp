require 'eventmachine'
require 'active_support/core_ext/hash/keys'
require 'yyrp/shadowsocks/connection'

require 'awesome_print'

module Yyrp
  class ShadowsocksServer
    attr_accessor :connections

    def initialize
      @connections = []
      Yyrp.set_config
    end

    def start
      ss_host = Yyrp.config.servers['ss']['host']
      ss_port = Yyrp.config.servers['ss']['port']
      pass = Yyrp.config.servers['ss']['password']
      method = Yyrp.config.servers['ss']['method']

      @signature = EventMachine.start_server(ss_host, ss_port, ShadowsocksConnection, pass, method) do |con|
        con.server = self
      end
      Yyrp.logger.info "ss server started on #{ss_port}"
      # add_config_file_listener
    end

    def stop
      EventMachine.stop
    end

    def add_config_file_listener
      config_md5 = Yyrp.file_md5(Yyrp.config_file)
      Yyrp.logger.info "Origin config file md5 is #{config_md5}"
      EM.add_periodic_timer(3) {
        # if file changed, reset config
        new_config_md5 = Yyrp.file_md5(Yyrp.config_file)
        if config_md5 != new_config_md5
          Yyrp.logger.info "It is time to reset config with md5 #{new_config_md5}"
          config_md5 = new_config_md5
          Yyrp.set_config
          ap Yyrp.config.rules
        end
      }
    end
  end
end
