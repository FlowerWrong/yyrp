require 'eventmachine'

require_relative 'base_adapter'
require_relative '../shadowsocks/crypto'

class ShadowsocksAdapter < BaseAdapter
  attr_accessor :crypto

  def initialize(client, crypto = nil, addr_to_send = nil)
    super(client)
    @crypto = crypto
    @addr_to_send = addr_to_send
  end

  def encrypt(buf)
    @crypto.encrypt(buf)
  end

  def decrypt(buf)
    @crypto.decrypt(buf)
  end

  def send_data data
    data = encrypt(data)
    super(data)
  end

  def post_init
    Yyrp.logger.debug [:post_init, :shadowsocks, @addr_to_send]
    send_data(@addr_to_send)
  end

  def receive_data(data)
    data = decrypt(data)
    @client.relay_from_backend(data)
  end

  def unbind
    super
  end
end
