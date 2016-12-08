require 'celluloid/dns'

module Dns
  class Server < Celluloid::DNS::Server
    def process(name, resource_class, transaction)
      p name, resource_class, transaction
      # TODO return faked ip if gfw domain
      @resolver ||= Celluloid::DNS::Resolver.new([[:udp, '114.114.114.114', 53]])
      transaction.passthrough!(@resolver)
    end
  end
end
