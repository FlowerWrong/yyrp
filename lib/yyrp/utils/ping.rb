require 'net/ping'

class Ping
  class << self
    def tcp_ping(host)
      ping = Net::Ping::TCP.new(host, 'http')
      if ping.ping?
        (ping.duration * 1000).to_i
      else
        nil
      end
    end

    # @return [avg max min] in ms
    def sys_ping(host, count = 5)
      res = `ping -c #{count} #{host}`
      return nil if res.nil?
      slices = res.slice(/(\.|\d|\/)+\//)
      return nil if slices.nil?
      slices.split('/')
    end
  end
end
