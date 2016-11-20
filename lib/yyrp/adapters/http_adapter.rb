require 'eventmachine'

require_relative 'base_adapter'

class HttpAdapter < BaseAdapter

  def post_init
    Yyrp.logger.debug [:post_init, :http]
  end

  def receive_data(data)
    @client.relay_from_backend(data)
  end

  def unbind
    super
    Yyrp.logger.debug [:unbind, :http]
  end
end
