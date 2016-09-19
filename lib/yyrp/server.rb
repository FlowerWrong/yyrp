require 'eventmachine'
require 'logging'
require 'active_support/core_ext/hash/keys'
require 'yyrp/http_proxy_server'
require 'yyrp/socks5_proxy_server'

module Yyrp
  class Server
    attr_accessor :connections

    def initialize
      @connections = []
      init_config
    end

    def init_config
      json_str = File.read(Yyrp.config_file)
      config_hash = JSON.parse(json_str)
      # config_hash.deep_symbolize_keys!
      Yyrp.configure do |config|
        config.servers = config_hash['servers']
        config.adapters = config_hash['adapters']
        config.rules = config_hash['rules']
        config.logger = Logging.logger(STDOUT)
        config.logger.level = :debug
      end
    end

    def start
      http_host = Yyrp.config.servers['http']['host']
      http_port = Yyrp.config.servers['http']['port']
      socks_host = Yyrp.config.servers['socks']['host']
      socks_port = Yyrp.config.servers['socks']['port']

      @signature_http = EventMachine.start_server(http_host, http_port, HttpProxyServer) do |con|
        con.server = self
      end
      @signature_socks5 = EventMachine.start_server(socks_host, socks_port, Socks5ProxyServer) do |con|
        con.server = self
      end
      Yyrp.logger.info "http and socks5 proxy server started on #{http_port} #{socks_port}"
    end

    def stop
      EventMachine.stop
      # EventMachine.stop_server(@signature_http)
      # EventMachine.stop_server(@signature_socks5)
      #
      # unless wait_for_connections_and_stop
      #   EventMachine.add_periodic_timer(1) { wait_for_connections_and_stop }
      # end
    end

    private

    def wait_for_connections_and_stop
      if @connections.empty?
        EventMachine.stop
        true
      else
        puts "Waiting for #{@connections.size} connection(s) to stop"
        false
      end
    end
  end
end
