require 'eventmachine'
require 'uuid'

require_relative '../adapters/direct_adapter'
require_relative 'crypto'

require 'yyrp/utils/relay'

class ShadowsocksConnection < EventMachine::Connection
  include Relay
  attr_accessor :crypto, :cached_pieces, :server

  def initialize(pass = 'liveneeq.com', method = 'aes-256-cfb')
    @crypto = Shadowsocks::Crypto.new(method: method, password: pass)
  end

  def encrypt(buf)
    @crypto.encrypt(buf)
  end

  def decrypt(buf)
    @crypto.decrypt(buf)
  end

  def post_init
    @relay = nil
    Yyrp.logger.info [:post_init, :shadowsocks_server, 'someone proxy connected to the shadowsocks server!']

    @stage = 0
    @cached_pieces = []
  end

  def receive_data data
    add_con
    data = decrypt(data)
    if @stage == 0
      @atype, @domain_len = data.unpack('C2')
      header_len = 2 + @domain_len + 2
      case @atype
        when 3
          @domain = data[2..(@domain_len + 1)]
          @port = data[(header_len-2)..header_len].unpack('S>').first
        else
          Yyrp.logger.info [:receive_data, @stage, "not support this atype: #{@atype}"]
          close_connection
          return
      end
      Yyrp.logger.info [:receive_data, @atype, @domain_len, @domain, @port]

      if @domain && @port
        @relay = EventMachine::connect @domain, @port, DirectAdapter, self
        if data.size > header_len
          @cached_pieces << data[header_len, data.size]
          # Yyrp.logger.info [:receive_data, :cached_pieces, @cached_pieces]
          @cached_pieces.each {|piece| @relay.send_data(piece)}
          @cached_pieces = nil
          @stage = 5
        end
      end
    elsif @stage == 5
      @relay.send_data(data)
    end
  end

  def unbind
    Yyrp.logger.info [:unbind, :shadowsocks_server]
    del_con
    @relay.close_connection_after_writing unless @relay.nil?
    @relay = nil
  end

  def relay_from_backend(data)
    data = encrypt(data)
    send_data data unless data.nil?
  end
end
