require 'yyrp/version'
require 'yyrp/http_proxy_server'
require 'yyrp/socks5_proxy_server'
require 'yyrp/config'
require 'yyrp/server'
require 'logging'

require 'yyrp/mitm/lib/ritm'

module Yyrp
  module_function

  def set_config
    json_str = File.read(config_file)
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

  def start_mitm
    set_config
    Ritm.on_request do |req|
      Yyrp.logger.info '=' * 20
      Yyrp.logger.info "on_request uri is #{req.request_uri}"
    end
    Ritm.on_response do |_req, res|
      Yyrp.logger.info '-' * 20
      Yyrp.logger.info "on_response headers is #{res.header}"
    end

    Yyrp.logger.info Yyrp.config.servers['mitm']['ca_key'], Yyrp.config.servers['mitm']['ca_crt']
    proxy = Ritm::Proxy::Launcher.new(
      ca_crt_path: Yyrp.config.servers['mitm']['ca_crt'],
      ca_key_path: Yyrp.config.servers['mitm']['ca_key']
    )
    Yyrp.logger.info "running https mitm server on 7779"
    proxy.start
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
