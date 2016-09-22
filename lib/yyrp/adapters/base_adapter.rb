require 'eventmachine'
require 'yyrp/base_proxy_server'

class BaseAdapter < BaseProxyServer
  def initialize(client)
    @client = client
  end

  def unbind
    @client.close_connection_after_writing unless @client.nil?
  end
end
