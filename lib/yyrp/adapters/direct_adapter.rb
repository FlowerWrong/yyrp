require 'eventmachine'

require_relative 'base_adapter'

class DirectAdapter < BaseAdapter
  def post_init
    Yyrp.logger.debug [:post_init, :direct]
  end

  def receive_data(data)
    @client.relay_from_backend(data)
  end

  def unbind
    super
    Yyrp.logger.debug [:unbind, :direct]
  end
end
