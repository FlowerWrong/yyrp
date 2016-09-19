require 'yyrp/version'
require 'yyrp/http_proxy_server'
require 'yyrp/socks5_proxy_server'
require 'yyrp/config'
require 'yyrp/server'

require 'yyrp/mitm/lib/ritm'

require 'awesome_print'

module Yyrp
  module_function

  def set_config
    json_str = File.read(config_file)
    config_hash = JSON.parse(json_str)
    Yyrp.configure do |config|
      config.servers = config_hash['servers']
      config.adapters = config_hash['adapters']
      config.rules = config_hash['rules']
    end
  end

  def start_mitm
    set_config
    Ritm.on_request do |req|
      p '=' * 20
      p "on_request uri is #{req.request_uri}"
    end
    Ritm.on_response do |_req, res|
      p '-' * 20
      p "on_response headers is #{res.header}"
    end

    p Yyrp.config.servers['mitm']['ca_key'], Yyrp.config.servers['mitm']['ca_crt']
    proxy = Ritm::Proxy::Launcher.new(
      ca_crt_path: Yyrp.config.servers['mitm']['ca_crt'],
      ca_key_path: Yyrp.config.servers['mitm']['ca_key']
    )
    puts "running https mitm server on 7779"
    proxy.start
  end

  def start
    set_config

    EventMachine::run {
      Signal.trap('INT') {stop_eventmachine}
      Signal.trap('TERM') {stop_eventmachine}
      http_host = Yyrp.config.servers['http']['host']
      http_port = Yyrp.config.servers['http']['port']
      socks_host = Yyrp.config.servers['socks']['host']
      socks_port = Yyrp.config.servers['socks']['port']
      EventMachine::start_server http_host, http_port, HttpProxyServer, true
      puts "running http proxy server on #{http_port}"
      EventMachine::start_server socks_host, socks_port, Socks5ProxyServer, true
      puts "running socks5 proxy server on #{socks_port}"
      config_md5 = file_md5(config_file)
      p "Origin config file md5 is #{config_md5}"
      EM.add_periodic_timer(3) {
        # if file changed, reset config
        new_config_md5 = file_md5(config_file)
        if config_md5 != new_config_md5
          p "It is time to reset config with md5 #{new_config_md5}"
          config_md5 = new_config_md5
          set_config
          ap Yyrp.config.rules
        end
      }
    }
  end

  def stop_eventmachine
    EventMachine.stop
  end

  def config_file
    File.expand_path('./config.json', Yyrp.root)
  end

  def file_md5(file)
    Digest::MD5.hexdigest File.read(file)
  end

  # Return the root path of this gem.
  #
  # @return [String] Path of the gem's root.
  def root
    File.dirname __dir__
  end

  # Return the lib path of this gem.
  #
  # @return [String] Path of the gem's lib.
  def lib
    File.join root, 'lib'
  end

  # Return the spec path of this gem.
  #
  # @return [String] Path of the gem's spec.
  def spec
    File.join root, 'spec'
  end
end
