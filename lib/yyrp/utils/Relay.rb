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
        @request.protocol = @https ? 'https' : 'http'
      end
      time_start = Time.now
      adapter, adapter_name = RuleManager.instance.adapter(@request)
      Yyrp.logger.debug [:to_relay, adapter, adapter_name]
      time_end = Time.now
      time = time_end - time_start
      Yyrp.logger.debug "Parse rule spent #{time.to_s}s"

      if adapter.nil?
        return false
      else
        if adapter == ShadowsocksAdapter
          @addr_to_send = [@atype, @domain_len].pack('CC') + @domain + [@port].pack('s>')
          ss_index = if adapter_name.nil?
                       0
                     else
                       shadowsocks_index_by_adapter_name(adapter_name)
                     end
          ss_config = Yyrp.config.adapters['shadowsocks'][ss_index]
          ss_host = ss_config['host']
          ss_port = ss_config['port']
          ss_method = ss_config['method']
          ss_passwd = ss_config['password']
          crypto = Shadowsocks::Crypto.new(method: ss_method, password: ss_passwd)
          begin
            @relay = EventMachine::connect ss_host, ss_port, ShadowsocksAdapter, self, crypto, @addr_to_send
          rescue => e
            Yyrp.logger.error e
            return false
          end
        elsif adapter == MitmAdapter
          mitm_config = Yyrp.config.servers['mitm']
          mitm_host = mitm_config['host']
          mitm_port = mitm_config['port']
          begin
            @relay = EventMachine::connect mitm_host, mitm_port, MitmAdapter, self
          rescue => e
            Yyrp.logger.error e
            return false
          end
        else
          # FIXME unable to resolve server address: Undefined error: 0 (EventMachine::ConnectionError)
          # https://www.altamiracorp.com/
          begin
            @relay = EventMachine::connect @domain, @port, adapter, self
          rescue => e
            Yyrp.logger.error e
            return false
          end
        end
      end
    end
    true
  end

  def shadowsocks_index_by_adapter_name(adapter_name)
    Yyrp.config.adapters['shadowsocks'].each_with_index do |ss, i|
      return i if ss['name'] == adapter_name
    end
  end
end
