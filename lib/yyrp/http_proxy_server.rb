require 'eventmachine'
require 'http/parser'
require 'uuid'
require 'awesome_print'

require_relative 'base_proxy_server'
require_relative 'adapters/direct_adapter'

require_relative 'utils/relay'

# initialize -> post_init -> server set con
class HttpProxyServer < BaseProxyServer
  include Relay
  attr_accessor :server

  def post_init
    @buff = ''
    @https = false
    @relay = nil
    @parser = Http::Parser.new(self)
  end

  def receive_data data
    add_con
    @buff << data
    if @https && @relay
      @relay.send_data(data)
    else
      begin
        @parser << data
      rescue => e # HTTP::Parser::Error
        Yyrp.logger.error e
      end
    end
  end

  def unbind
    del_con
    @https = nil
  end

  def on_message_begin
    @headers = nil
    @body = ''
  end

  def on_headers_complete(headers)
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

    Yyrp.logger.debug [:on_headers_complete, :http_proxy_server, @domain, @port, @atype, @domain_len]

    if to_relay
      if @parser.http_method == 'CONNECT'
        @https = true
        send_data("HTTP/1.1 200 Connection Established\r\n\r\n")
      else
        @relay.send_data(@buff) if @buff != '' && @buff != nil
        @buff = ''
      end
    else
      reject_reply
      return
    end
  end

  def on_body(chunk)
    @body << chunk
  end

  def on_message_complete
    # TODO add request body
    if @domain =~ /.*163.*/ || @domain =~ /.*126.*/ || @domain =~ /.*music.*/
      Yyrp.logger.debug '-' * 30
      Yyrp.logger.debug @parser.request_url
      Yyrp.logger.debug @headers
      Yyrp.logger.debug @body
    end
  end

  #
  # relay data from backend server to client
  #
  def relay_from_backend(data)
    send_data data unless data.nil?
  end
end
