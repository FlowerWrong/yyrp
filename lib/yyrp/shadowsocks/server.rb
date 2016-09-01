require 'eventmachine'
require 'uuid'

require_relative '../adapters/direct_adapter'
require_relative 'crypto'

class ShadowsocksServer < EventMachine::Connection
  attr_accessor :crypto, :cached_pieces

  def initialize(pass = 'liveneeq.com', method = 'aes-256-cfb', debug = false)
    @debug = debug
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
    debug [:post_init, :shadowsocks_server, 'someone proxy connected to the shadowsocks server!']

    @stage = 0
    @cached_pieces = []
  end

  def receive_data data
    data = decrypt(data)
    debug [:receive_data, data]
    if @stage == 0
      @atype, @domain_len = data.unpack('C2')
      header_len = 2 + @domain_len + 2
      case @atype
        when 3
          @domain = data[2..(@domain_len + 1)]
          @port = data[(header_len-2)..header_len].unpack('S>').first
        else
          debug [:receive_data, @stage, "not support this atype: #{@atype}"]
          return
      end
      debug [:receive_data, @atype, @domain_len, @domain, @port]

      @relay = EventMachine::connect @domain, @port, DirectAdapter, self, @debug

      if data.size > header_len
        @cached_pieces << data[header_len, data.size]
        debug [:receive_data, :cached_pieces, @cached_pieces]
        @cached_pieces.each {|piece| @relay.send_data(piece)}
        @cached_pieces = nil
        @stage = 5
      end
    elsif @stage == 5
      @relay.send_data(data)
    end
  end

  def unbind
    debug [:unbind, :shadowsocks_server]
    @relay.close_connection_after_writing unless @relay.nil?
    @relay = nil
  end

  #
  # relay data from backend server to client
  #
  def relay_from_backend(data)
    data = encrypt(data)
    debug [:relay_from_backend, :shadowsocks_server, data]
    send_data data unless data.nil?
  end

  def debug(*data)
    if @debug
      require 'pp'
      pp data
      puts
    end
  end
end
