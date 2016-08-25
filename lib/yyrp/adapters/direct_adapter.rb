require 'eventmachine'

require_relative 'base_adapter'

class DirectAdapter < BaseAdapter
  def post_init
    debug [:post_init, :direct]
  end

  def receive_data(data)
    # debug [:receive_data, :direct, data]
    @client.relay_from_backend(data)
  end

  def unbind
    super
    debug [:unbind, :direct]
  end
end
