require_relative './session_struct'
require 'singleton'

module Dns
  module Nat
    class Session
      include Singleton
      attr_accessor :sessions # SessionStruct
    end
  end
end
