require 'eventmachine'

class BaseAdapter < EventMachine::Connection

  def initialize(client)
    super
    @client = client
  end

  def unbind
    @client.close_connection_after_writing unless @client.nil?
  end
end
