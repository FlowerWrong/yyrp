require 'eventmachine'
require 'uuid'

require 'yyrp/adapters/direct_adapter'
require 'yyrp/utils/relay'

require 'yyrp/shadowsocks/crypto'
require 'yyrp/shadowsocks/server_pool'
require 'yyrp/config'
require 'yyrp/base_proxy_server'

class ShadowsocksConnection < BaseProxyServer
  include Relay
  attr_accessor :crypto, :cached_pieces, :listen_port, :server

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
    @stage = 0
    @cached_pieces = []
  end

  def receive_data data
    add_con
    # 流量 data.size
    data = decrypt(data)
    stage_handler(data)
  end

  def stage_handler(data)
    if @stage == 0
      @atype, @domain_len = data.unpack('C2')
      return if @domain_len.nil?
      header_len = 2 + @domain_len + 2
      # https://github.com/shadowsocks/shadowsocks-libev/blob/master/src/server.c#L679
      case @atype
        when 1 # 1: ipv4, 4 bytes
          @domain = inet_ntoa(data[1..4])
          @port = data[5..6].unpack('S>').first
          Yyrp.logger.info "ipv4 ip is #{@domain}, port is #{@port}"
          # FIXME on android it may be DNS query over tcp
          # stage_handler(data[7..(data.size - 1)])
        when 3 # domain
          @domain = data[2..(@domain_len + 1)]
          @port = data[(header_len-2)..header_len].unpack('S>').first
        when 4 # 4: ipv6, 16 bytes
          @domain = inet_ntoa(data[1..15])
          @port = data[16..17].unpack('S>').first
          Yyrp.logger.info "ipv6 ip is #{@domain}, port is #{@port}"
        else
          Yyrp.logger.info [:receive_data, @stage, "not support this atype: #{@atype}"]
          close_connection
          return
      end
      Yyrp.logger.info [:receive_data, @atype, @domain_len, @domain, @port]

      if @domain && @port
        begin
          @relay = EventMachine::connect @domain, @port, DirectAdapter, self
        rescue => e
          Yyrp.logger.error e
          close_connection
          return
        end
        if data.size > header_len
          @cached_pieces << data[header_len, data.size]
          @cached_pieces.each {|piece| @relay.send_data(piece)}
          @cached_pieces = nil
        end
        @stage = 5
      end
    elsif @stage == 5
      @relay.send_data(data)
    end
    outbound_scheduler(@relay) if @relay
  end

  def unbind
    Yyrp.logger.info [:unbind, :shadowsocks_server]
    del_con
    @relay.close_connection_after_writing unless @relay.nil?
    @relay = nil
  end

  def relay_from_backend(data)
    # 流量 data.size

    data = encrypt(data)
    send_data data unless data.nil?
  end

  private

  def inet_ntoa(n)
    n.unpack("C*").join "."
  end
end
