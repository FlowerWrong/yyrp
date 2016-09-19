require 'eventmachine'

class BaseProxyServer < EventMachine::Connection
  attr_accessor :server

  def initialize
  end
end
