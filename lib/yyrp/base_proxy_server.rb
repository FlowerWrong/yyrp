require 'eventmachine'

class BaseProxyServer < EventMachine::Connection
  BackpressureLevel = 524288 # 512k

  def initialize
  end

  def over_pressure?(relay)
    relay.get_outbound_data_size > BackpressureLevel
  end

  def outbound_scheduler(relay)
    if over_pressure?(relay)
      pause unless paused?
      EM.add_timer(0.2) { outbound_scheduler(relay) }
    else
      resume if paused?
    end
  end
end
