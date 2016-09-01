require 'eventmachine'

class BaseProxyServer < EventMachine::Connection
  def initialize(debug = false)
    @debug = debug
  end

  def debug(*data)
    if @debug
      require 'pp'
      pp data
      puts
    end
  end
end
