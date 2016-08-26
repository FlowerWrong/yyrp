require 'eventmachine'
require 'uuid'

require_relative '../msgs/request'
require_relative '../rules/rule_manager'
require_relative '../adapters/shadowsocks_adapter'
require_relative '../adapters/direct_adapter'
require_relative '../adapters/mitm_adapter'

require_relative '../config'

module Relay
  def to_relay
    if @relay.nil?
      req = Request.new(@domain, @port)
      adapter, adapter_name = RuleManager.instance.adapter(req)
      debug [:to_relay, adapter, adapter_name]

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
            @relay = EventMachine::connect ss_host, ss_port, ShadowsocksAdapter, self, @debug, crypto, @addr_to_send
          rescue => e
            p e
            return false
          end
        elsif adapter == MitmAdapter
          mitm_config = Yyrp.config.servers['mitm']
          mitm_host = mitm_config['host']
          mitm_port = mitm_config['port']
          begin
            @relay = EventMachine::connect mitm_host, mitm_port, MitmAdapter, self, @debug
          rescue => e
            p e
            return false
          end
        else
          # FIXME unable to resolve server address: Undefined error: 0 (EventMachine::ConnectionError)
          # https://www.altamiracorp.com/
          begin
            @relay = EventMachine::connect @domain, @port, adapter, self, @debug
          rescue => e
            p e
            return false
          end
        end
        session = UUID.generate
        @connections << {session: session, relay: @relay}
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
