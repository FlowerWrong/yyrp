require 'singleton'

module Dns
  module Fake
    class Session
      include Singleton
      attr_accessor :sessions # {domain: ip}
    end
  end
end
