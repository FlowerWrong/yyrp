require 'eventmachine'
require 'http/parser'
require 'uuid'

require_relative 'base_proxy_server'
require_relative 'adapters/direct_adapter'
require_relative 'adapters/shadowsocks_adapter'
require_relative 'shadowsocks/crypto'

require_relative 'rules/rule_manager'
require_relative 'msgs/request'

require_relative 'utils/relay'

class Socks5ProxyServer < BaseProxyServer
  include Relay
  attr_accessor :server

  def post_init
    @relay = nil
    @buff = ''
    @stage = 1 # 1:协商版本及认证方式 2:请求信息
  end

  def receive_data data
    add_con
    # https://zh.wikipedia.org/wiki/SOCKS#SOCKS5
    # http://apidock.com/ruby/String/unpack
    if @stage == 1
      # \x05\x02\x00\x01
      data = data.unpack('CCC')
      version = data[0]
      nmethods = data[1]
      methods = data[2]
      if version != 5
        Yyrp.logger.error [:receive_data, @stage, 'not support this socks version, just support 5']
        return
      end
      send_data [5, 0].pack('CC')
      @stage = 2
    elsif @stage == 2
      _, cmd, _, @atype, @domain_len = data.unpack('C5')
      case @atype
        when 1 # 1: ipv4, 4 bytes
          ip = data[5..8]
          @domain = ip
          @port = data[9..10].unpack('S>').first
        when 4 # 4: ipv6, 16 bytes
          ip = data[5..20]
          @domain = ip
          @port = data[21..22].unpack('S>').first
        when 3 # domain name
          @domain = data[5..(@domain_len + 4)]
          len = data.size
          @port = data[(len-2)..len].unpack('S>').first
        else
          Yyrp.logger.error [:receive_data, @stage, 'not support this atype']
          return
      end
      Yyrp.logger.debug [:receive_data, :socks5_proxy_server, cmd, @domain, @port, @atype, @domain_len]

      if @domain && @port
        case cmd
          when 1 # CONNECT请求
            send_data("\x05\x00\x00\x01\x00\x00\x00\x00" + [@port].pack('s>'))
          when 2, 3 # bind: FTP, udp
            Yyrp.logger.debug [:receive_data, @stage, 'not support this cmd']
            return
          else
            Yyrp.logger.debug [:receive_data, @stage, 'not support this cmd']
            return
        end
        @stage = 5
      else
        Yyrp.logger.error [:receive_data, @domain, @port]
        return
      end
    elsif @stage == 5
      @buff << data
      if data =~ /.*\s(.*)\sHTTP\/1\.1.*/
        @parser = Http::Parser.new(self)
        @parser << data
      else
        if to_relay
          @relay.send_data(@buff)
          @buff = ''
        else
          reject_reply
          return
        end
      end
    else
      Yyrp.logger.error [:receive_data, @stage, 'not support this stage']
      return
    end
  end

  def unbind
    del_con
    @stage = nil
  end

  def on_message_begin
    @headers = nil
    @body = ''
  end

  def on_headers_complete(headers)
    # headers.delete('Proxy-Connection')
    @headers = headers
    if to_relay
      @relay.send_data(@buff)
      @buff = ''
    else
      close_connection
      return
    end
  end

  def on_body(chunk)
    @body << chunk
  end

  def on_message_complete
  end

  #
  # relay data from backend server to client
  #
  def relay_from_backend(data)
    send_data data unless data.nil?
  end
end
