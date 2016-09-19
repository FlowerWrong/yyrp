require 'eventmachine'
require 'http/parser'
require 'uuid'
require 'awesome_print'

require_relative 'base_proxy_server'
require_relative 'adapters/direct_adapter'

require_relative 'utils/relay'


class HttpProxyServer < BaseProxyServer
  include Relay

  def post_init
    @buff = ''
    @https = false
    @relay = nil
    @parser = Http::Parser.new(self)

    debug [:post_init, :http_proxy_server, 'someone proxy connected to the http proxy server!']
  end

  def receive_data data
    # debug [:receive_data, :http_proxy_server, data]
    @buff << data
    if @https && @relay
      @relay.send_data(data)
    else
      begin
        @parser << data
      rescue => e # HTTP::Parser::Error
        p e
      end
    end
  end

  def unbind
    debug [:unbind, :http_proxy_server]
    @relay.close_connection_after_writing unless @relay.nil?
    @https = false
    @relay = nil
    @parser = nil
    @buff = nil
  end

  def on_message_begin
    @headers = nil
    @body = ''
  end

  def on_headers_complete(headers)
    debug [:on_headers_complete, :http_proxy_server, @parser.http_version, @parser.http_method, @parser.request_url, @parser.status_code, @parser.headers]

    # headers.delete('Proxy-Connection')
    @headers = headers
    @domain, @port = headers['Host'].split(':')
    if @parser.http_method == 'CONNECT'
      @domain, @port = @parser.request_url.split(':')
      @port = @port.nil? ? 443 : @port.to_i
    else
      @port = @port.nil? ? 80 : @port.to_i
    end
    @atype, @domain_len = 3, @domain.size

    debug [:on_headers_complete, :http_proxy_server, @domain, @port, @atype, @domain_len]

    if to_relay
      if @parser.http_method == 'CONNECT'
        @https = true
        send_data("HTTP/1.1 200 Connection Established\r\n\r\n")
      else
        @relay.send_data(@buff) if @buff != '' && @buff != nil
        @buff = ''
      end
    else
      debug [:on_headers_complete, "Maybe #{@domain} is reject, now close socket"]
      # send_data("HTTP/1.1 200 OK\r\nContent-Length: 0\r\nConnection: close\r\n\r\n")
      # timer = EventMachine.add_timer(3) do
      #   close_connection_after_writing
      # end
      close_connection_after_writing and return
    end
  end

  def on_body(chunk)
    @body << chunk
  end

  def on_message_complete
    # debug [:on_message_complete, :http_proxy_server, @headers, @body]
    # TODO add request body
  end

  #
  # relay data from backend server to client
  #
  def relay_from_backend(data)
    # debug [:relay_from_backend, :http_proxy_server, data]
    send_data data unless data.nil?
  end
end
