require 'eventmachine'
require 'uuid'

require_relative '../msgs/request'
require_relative '../rules/rule_manager'
require_relative '../adapters/shadowsocks_adapter'
require_relative '../adapters/direct_adapter'
require_relative '../adapters/mitm_adapter'

require_relative '../config'

module Relay
  def add_con
    unless @server.connections.include?(self)
      @server.connections << self
      Yyrp.logger.info "@server.connections +1 count is #{@server.connections.size}"
    end
  end

  def rewrite_headers(headers, client_ip, protocol = 'http')
    headers['x-real-ip'] = client_ip unless headers['x-real-ip']
    if headers['x-forwarded-for']
      headers['x-forwarded-for'] += ", #{client_ip}"
    else
      headers['x-forwarded-for'] = client_ip
    end
    if headers['x-forwarded-proto']
      headers['x-forwarded-proto'] += ", #{protocol}"
    else
      headers['x-forwarded-proto'] = protocol
    end
    headers
  end

  def del_con
    @server.connections.delete(self)
    Yyrp.logger.info "@server.connections -1 count is #{@server.connections.size}"
    @relay.close_connection_after_writing unless @relay.nil?
    @relay = nil
    @parser = nil
    @buff = nil
  end

  def reject_reply
    # FIXME it will retry
    Yyrp.logger.debug [:on_headers_complete, "Maybe #{@domain} is reject, now close socket"]
    # send_data("HTTP/1.1 200 OK\r\nContent-Length: 0\r\nConnection: close\r\n\r\n")
    # timer = EventMachine.add_timer(3) do
    #   close_connection_after_writing
    # end
    close_connection_after_writing
  end

  def to_relay
    if @relay.nil?
      @request = Request.new(@domain, @port)
      if @parser
        @request.method = @parser.http_method
        @request.http_version = @parser.http_version
        @request.request_url = @parser.request_url
        @request.headers = @parser.headers
        @request.protocol = @protocol
      end

      # DNS query
      if @request.ip_address
        time_start = Time.now
        adapter, adapter_name = RuleManager.instance.adapter(@request)
        Yyrp.logger.debug [:to_relay, adapter, adapter_name]
        time_end = Time.now
        time = time_end - time_start
        if time > 1
          Yyrp.logger.error '---------------------------------------------------'
          Yyrp.logger.error "Parse rule spent #{time.to_s}s"
        end
      else
        adapter, adapter_name = ShadowsocksAdapter, Yyrp.config.adapters['shadowsocks'][0]['name']
      end

      if adapter.nil?
        return false
      else
        if adapter == ShadowsocksAdapter
          @addr_to_send = [@atype, @domain_len].pack('CC') + @domain + [@port].pack('s>')
          ss_index = index_by_adapter_name(adapter_name, 'shadowsocks')

          ss_config = Yyrp.config.adapters['shadowsocks'][ss_index]
          ss_host = ss_config['host']
          ss_port = ss_config['port']
          ss_method = ss_config['method']
          ss_passwd = ss_config['password']
          crypto = Shadowsocks::Crypto.new(method: ss_method, password: ss_passwd)
          begin
            @relay = EventMachine::connect ss_host, ss_port, adapter, self, crypto, @addr_to_send
          rescue => e
            Yyrp.logger.error "#{__FILE__} #{__LINE__} #{e}"
            return false
          end
        elsif adapter == MitmAdapter
          if @connect_method
            mitm_config = Yyrp.config.servers['mitm']
            mitm_host = mitm_config['host']
            mitm_port = mitm_config['port']
            begin
              @relay = EventMachine::connect mitm_host, mitm_port, adapter, self
            rescue => e
              Yyrp.logger.error "#{__FILE__} #{__LINE__} #{e}"
              return false
            end
          else # 非https使用直连
            begin
              @relay = EventMachine::connect @domain, @port, adapter, self
            rescue => e
              Yyrp.logger.error "#{__FILE__} #{__LINE__} #{e}"
              return false
            end
          end
        elsif adapter == HttpAdapter
          index = index_by_adapter_name(adapter_name, 'http')
          http_config = Yyrp.config.adapters['http'][index]
          host = http_config['host']
          port = http_config['port']
          begin
            @relay = EventMachine::connect host, port, adapter, self, http_config
          rescue => e
            Yyrp.logger.error "#{__FILE__} #{__LINE__} #{e}"
            return false
          end
        else
          begin
            @relay = EventMachine::connect @domain, @port, adapter, self
          rescue => e
            Yyrp.logger.error "#{__FILE__} #{__LINE__} #{e}"
            return false
          end
        end
      end
    end
    true
  end

  def index_by_adapter_name(adapter_name, adapter_type)
    return 0 if adapter_name.nil?
    index = 0
    Yyrp.config.adapters[adapter_type].each_with_index do |ad, i|
      if ad['name'] == adapter_name
        index = i
        break
      end
    end
    index
  end
end
