require 'eventmachine'
require 'http/parser'
require 'uuid'
require 'public_suffix'

require 'yyrp/filters/filter_manager'

require 'yyrp/msgs/response'

require_relative 'base_proxy_server'
require_relative 'adapters/direct_adapter'

require_relative 'utils/relay'

# TODO
class HttpsProxyServer < BaseProxyServer
  include Relay
  attr_accessor :server, :request, :response

  def post_init
    start_tls private_key_file: Yyrp.config.servers['mitm']['ca_key'], cert_chain_file: Yyrp.config.servers['mitm']['ca_crt'], verify_peer: false
  end

  def receive_data data
  end

  def unbind
  end
end
