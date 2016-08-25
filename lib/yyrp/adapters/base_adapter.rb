require 'eventmachine'

class BaseAdapter < EventMachine::Connection

  def initialize(client, debug = false)
    super
    @client = client
    @debug = debug
  end

  def debug(*data)
    return unless @debug
    require 'pp'
    pp data
    puts
  end

  def unbind
    @client.close_connection_after_writing unless @client.nil?
  end
end
