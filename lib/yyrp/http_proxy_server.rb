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
    @connect_method = false
    @relay = nil
    @parser = Http::Parser.new(self)
  end

  def receive_data data
    add_con

    @client_port, @client_ip = Socket.unpack_sockaddr_in(get_peername)
    # Yyrp.logger.info "Received data #{data.size} from #{@client_ip}:#{@client_port}"

    @buff += data
    @relay.send_data(data) if @connect_method && !@relay.nil? # https only
    unless @connect_method
      begin
        @parser << data
      rescue => e # HTTP::Parser::Error
        Yyrp.logger.error "#{__FILE__} #{__LINE__} #{e}".colorize(:red)
      end
    end
  end

  def unbind
    del_con
    @connect_method = nil
  end

  # 开始接收客户端数据
  def on_message_begin
    @headers = nil
    @body = ''
  end

  def on_headers_complete(headers)
    # @see https://imququ.com/post/the-proxy-connection-header-in-http-request.html
    @headers = headers
    Yyrp.logger.error('headers is empty') if @headers.nil? || @headers.empty?

    # get remote domain and port
    if @parser.http_method == 'CONNECT'
      @domain, @port = @parser.request_url.split(':')
      @port = @port.nil? ? 443 : @port.to_i
      @connect_method = true # https ws or wss
    else
      @domain, @port = (headers['Host'] || headers['host']).split(':')
      @port = @port.nil? ? 80 : @port.to_i
    end

    # 验证域名是否有效
    unless PublicSuffix.valid?(@domain, ignore_private: true)
      Yyrp.logger.error "Invide domain name #{@domain}".colorize(:red)
      return
    end

    # 是否文件上传
    if @headers['Content-Type'] && @headers['Content-Type'] =~ /multipart\/form-data;\s+boundary=(.*+)/
      boundary = $1
      Yyrp.logger.info "It is fileupload, boundary is #{boundary}"
    end

    @protocol = if @parser.http_method != 'CONNECT'
      'https_or_ws_or_wss'
    else
      'http'
    end

    # handle headers
    # @headers = rewrite_headers(@headers, @client_ip, @protocol)

    @atype, @domain_len = 3, @domain.size

    Yyrp.logger.debug [:on_headers_complete, :http_proxy_server, @domain, @port, @atype, @domain_len]

    if to_relay
      if @parser.http_method == 'CONNECT'
        send_data("HTTP/1.1 200 Connection Established\r\n\r\n")
      else
        request_line = @buff.split("\r\n")[0]
        if @relay.upstream_config && @relay.upstream_config['auth']
          @headers['Proxy-Authorization'] = "Basic #{Base64.encode64("#{@relay.upstream_config['username']}:#{@relay.upstream_config['password']}")}"
        end
        payload = request_line + "\r\n" + @headers.keys.map {|key| "#{key}: #{@headers[key]}"}.join("\r\n") + "\r\n\r\n"

        @relay.send_data(payload) if payload
        @buff = ''
      end
    else
      reject_reply
    end
  end

  def on_body(chunk)
    @body << chunk
    @relay.send_data(chunk) if !@connect_method && @relay # http only
  end

  def on_message_complete
    if @request && @body
      @body.size < 200 ? @request.body = @body : @request.body = @body[0..200]
    end
    if @request && FilterManager.instance.match(@request)
      p '-' * 50
      Yyrp.logger.debug "request body size is #{@body.size}"
      Yyrp.logger.debug "request is #{@request.inspect}"
      p '-' * 20
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
      Yyrp.logger.debug "response is #{@response.all_data.join('')}"
      p '*' * 20
    end
    send_data data unless data.nil?
  end
end
