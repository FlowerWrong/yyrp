require 'eventmachine'
require 'http/parser'
require 'uuid'
require 'public_suffix'

require 'yyrp/filters/filter_manager'

require 'yyrp/msgs/response'

require_relative 'base_proxy_server'
require_relative 'adapters/direct_adapter'

require_relative 'utils/relay'

# initialize -> post_init -> server set con
class HttpProxyServer < BaseProxyServer
  include Relay
  attr_accessor :server, :request, :response

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
        Yyrp.logger.error "#{__FILE__} #{__LINE__} #{e}"
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
    # @see https://imququ.com/post/the-proxy-connection-header-in-http-request.html
    # headers.delete('Proxy-Connection')
    # headers['Connection'] = 'keep-alive'
    @headers = headers
    # TODO rewrite http headers
    if @headers.empty? || @headers.nil?
      Yyrp.logger.error 'headers is empty'
    end
    if @parser.http_method == 'CONNECT'
      @domain, @port = @parser.request_url.split(':')
      @port = @port.nil? ? 443 : @port.to_i
    else
      @domain, @port = (headers['Host'] || headers['host']).split(':')
      @port = @port.nil? ? 80 : @port.to_i
    end

    unless PublicSuffix.valid?(@domain, ignore_private: true)
      Yyrp.logger.error "Invide domain name #{@domain}"
      return
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
    if @request && @body
      @body.size < 200 ? @request.body = @body : @request.body = @body[0..200]
    end
    if @request && FilterManager.instance.match(@request)
      # unless @parser.request_url.start_with? 'http://talkapp.ntpc.gov.tw/newntpc_webservice/Service1.svc/getAreaRoad'
      p '-' * 50
      Yyrp.logger.debug @request.inspect
      p '-' * 20
      # end
    end
  end

  #
  # relay data from backend server to client
  #
  def relay_from_backend(data)
    @response = Response.new if @response.nil?
    @response.all_data << data
    if @request && FilterManager.instance.match(@request)
      p '*' * 50
      Yyrp.logger.debug @response.all_data.join('')
      p '*' * 20
    end
    send_data data unless data.nil?
  end
end
