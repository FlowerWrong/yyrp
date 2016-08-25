require 'eventmachine'

require_relative 'base_adapter'

class MitmAdapter < BaseAdapter
  def post_init
    debug [:post_init, :mitm]
  end

  def receive_data(data)
    @client.relay_from_backend(data)
  end

  def unbind
    super
    debug [:unbind, :mitm]
  end
end