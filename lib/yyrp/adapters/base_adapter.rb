require 'eventmachine'
require 'yyrp/base_proxy_server'

class BaseAdapter < BaseProxyServer
  attr_accessor :upstream_config

  def initialize(client, upstream_config = nil)
    @client = client
    @upstream_config = upstream_config
  end

  def unbind
    @client.close_connection_after_writing unless @client.nil?
  end
end
