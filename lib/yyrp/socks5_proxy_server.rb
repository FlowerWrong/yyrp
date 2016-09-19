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

  def post_init
    @relay = nil
    @buff = ''
    @stage = 1 # 1:协商版本及认证方式 2:请求信息
    debug [:post_init, :socks5_proxy_server, 'someone proxy connected to the socks5 proxy server!']
  end

  def receive_data data
    # debug [:receive_data, :socks5_proxy_server, @stage, data]
    # https://zh.wikipedia.org/wiki/SOCKS#SOCKS5
    # http://apidock.com/ruby/String/unpack
    if @stage == 1
      # \x05\x02\x00\x01
      data = data.unpack('CCC')
      version = data[0]
      nmethods = data[1]
      methods = data[2]
      debug [:receive_data, version, nmethods, methods]
      if version != 5
        debug [:receive_data, @stage, 'not support this socks version, just support 5']
        return
      end
      send_data [5, 0].pack('CC')
      @stage = 2
    elsif @stage == 2
      _, cmd, _, @atype, @domain_len = data.unpack('C5')
      case @atype
        when 1 # 1: ipv4, 4 bytes
          ip = data[5..9]
          @domain = ip
          @port = data[9..11].unpack('S>').first
        when 4 # 4: ipv6, 16 bytes
          ip = data[5..21]
          @domain = ip
          @port = data[21..23].unpack('S>').first
        when 3 # domain name
          @domain = data[5..(@domain_len + 4)]
          len = data.size
          @port = data[(len-2)..len].unpack('S>').first
        else
          debug [:receive_data, @stage, 'not support this atype']
          return
      end
      debug [:receive_data, :socks5_proxy_server, cmd, @domain, @port, @atype, @domain_len]

      case cmd
        when 1 # CONNECT请求
          send_data("\x05\x00\x00\x01\x00\x00\x00\x00" + [@port].pack('s>'))
        when 2, 3 # bind: FTP, udp
          debug [:receive_data, @stage, 'not support this cmd']
          return
        else
          debug [:receive_data, @stage, 'not support this cmd']
          return
      end
      @stage = 5
    elsif @stage == 5
      @buff << data
      if data =~ /.*\s(.*)\sHTTP\/1\.1.*/
        # debug [:receive_data, 'http']
        @parser = Http::Parser.new(self)
        @parser << data
      else
        # debug [:receive_data, 'https']
        if to_relay
          @relay.send_data(@buff)
          @buff = ''
        else
          # FIXME it will retry
          debug [:receive_data, "Maybe #{@domain} is reject, now close socket"]
          # send_data("HTTP/1.1 200 OK\r\nContent-Length: 0\r\nConnection: close\r\n\r\n")
          # timer = EventMachine.add_timer(3) do
          #   close_connection_after_writing
          # end
          close_connection_after_writing and return
        end
      end
    else
      debug [:receive_data, @stage, 'not support this stage']
      return
    end
  end

  def unbind
    debug [:unbind, :socks5_proxy_server]
    @relay.close_connection_after_writing unless @relay.nil?
    @relay = nil
    @parser = nil
    @buff = nil
    @stage = nil
  end

  def on_message_begin
    @headers = nil
    @body = ''
  end

  def on_headers_complete(headers)
    headers.delete('Proxy-Connection')
    debug [:on_headers_complete, :socks5_proxy_server, headers.inspect]
    @headers = headers
    if to_relay
      @relay.send_data(@buff)
      @buff = ''
    else
      close_connection and return
    end
  end

  def on_body(chunk)
    @body << chunk
  end

  def on_message_complete
    debug [:on_message_complete, :socks5_proxy_server, @headers, @body]
  end

  #
  # relay data from backend server to client
  #
  def relay_from_backend(data)
    # debug [:relay_from_backend, :socks5_proxy_server, data]
    send_data data unless data.nil?
  end
end
