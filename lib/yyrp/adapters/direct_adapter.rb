require 'eventmachine'

require_relative 'base_adapter'

class DirectAdapter < BaseAdapter
  def post_init
  end

  def receive_data(data)
    @client.relay_from_backend(data)
  end

  def unbind
    super
  end
end
