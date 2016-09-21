require 'eventmachine'
require 'uuid'

require_relative '../adapters/direct_adapter'
require_relative 'crypto'

require 'yyrp/utils/relay'
require 'yyrp/shadowsocks/models'
require 'yyrp/shadowsocks/server_pool'
require 'yyrp/config'


class ShadowsocksConnection < EventMachine::Connection
  include Relay
  attr_accessor :crypto, :cached_pieces, :server, :listen_port

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
    # 更新用户流量到数据库
    user = get_user
    user.update(flow_up: user.flow_up + data.size) unless user.nil?

    data = decrypt(data)
    if @stage == 0
      @atype, @domain_len = data.unpack('C2')
      header_len = 2 + @domain_len + 2
      # FIXME [:receive_data, 0, "not support this atype: 22"]
      case @atype
        # TODO
        # when 1 # 1: ipv4, 4 bytes
        #   ip = data[5..9]
        #   @domain = ip
        #   @port = data[9..11].unpack('S>').first
        # when 4 # 4: ipv6, 16 bytes
        #   ip = data[5..21]
        #   @domain = ip
        #   @port = data[21..23].unpack('S>').first
        when 3 # domain
          @domain = data[2..(@domain_len + 1)]
          @port = data[(header_len-2)..header_len].unpack('S>').first
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
  end

  def unbind
    Yyrp.logger.info [:unbind, :shadowsocks_server]
    del_con
    @relay.close_connection_after_writing unless @relay.nil?
    @relay = nil
  end

  def relay_from_backend(data)
    # 更新用户流量到数据库
    user = get_user
    user.update(flow_down: user.flow_down + data.size) unless user.nil?

    data = encrypt(data)
    send_data data unless data.nil?
  end

  private

  def get_user
    users = User.where(enable: true, port: @listen_port)
    users != [] ? users.last : nil
  end
end
