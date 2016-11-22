require 'eventmachine'
require 'active_support/core_ext/hash/keys'
require 'yyrp/http_proxy_server'
require 'yyrp/https_proxy_server'
require 'yyrp/socks5_proxy_server'

require 'awesome_print'
require 'colorize'

module Yyrp
  class Server
    attr_accessor :connections

    def initialize
      @connections = []
      Yyrp.set_config
    end

    def start
      http_host = Yyrp.config.servers['http']['host']
      http_port = Yyrp.config.servers['http']['port']
      socks_host = Yyrp.config.servers['socks']['host']
      socks_port = Yyrp.config.servers['socks']['port']

      @signature_http = EventMachine.start_server(http_host, http_port, HttpProxyServer) do |con|
        con.server = self
      end
      @signature_http = EventMachine.start_server(http_host, (http_port + 10), HttpsProxyServer) do |con|
        con.server = self
      end
      @signature_socks5 = EventMachine.start_server(socks_host, socks_port, Socks5ProxyServer) do |con|
        con.server = self
      end
      Yyrp.logger.info "http, https and socks5 proxy server started on #{http_port} #{http_port + 10} #{socks_port}".colorize(:blue)
      add_config_file_listener
    end

    def stop
      EventMachine.stop
    end

    def add_config_file_listener
      config_md5 = Yyrp.file_md5(Yyrp.config_file)
      Yyrp.logger.info "Origin config file md5 is #{config_md5}".colorize(:light_blue)
      EM.add_periodic_timer(3) {
        # if file changed, reset config
        new_config_md5 = Yyrp.file_md5(Yyrp.config_file)
        if config_md5 != new_config_md5
          Yyrp.logger.info "It is time to reset config with md5 #{new_config_md5}".colorize(:red).on_blue
          config_md5 = new_config_md5
          Yyrp.set_config
          ap Yyrp.config.rules
        end
      }
    end
  end
end
