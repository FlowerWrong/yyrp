require 'ipaddress'
require 'ipaddr'

require_relative '../adapters/direct_adapter'
require_relative '../adapters/http_adapter'
require_relative '../adapters/shadowsocks_adapter'

class BaseRule
  attr_accessor :action, :type, :list, :adapter_name, :matched_rule
  def initialize(type, action)
    raise("Type #{type} not support for this rule") unless types.include?(type)
    raise("Action #{action} not support for this rule") unless actions.include?(action)
    @type = type
    @action = action
  end

  def description
    "rule: type-#{@type} action-#{@action} list-#{@list[0]}"
  end

  def types
    %w(domain domain_keyword domain_suffix geoip ip_cidr other)
  end

  def actions
    %w(http shadowsocks direct speed reject mitm)
  end

  def match(req)
    case @type
      when 'domain'
        @list.each do |d|
          if d == req.only_host
            @matched_rule = ['domain', d, req.description]
            return true
          end
        end unless @list.nil?
      when 'domain_keyword'
        @list.each do |key|
          reg = /.*#{key}.*/
          if reg =~ req.only_host
            @matched_rule = ['domain_keyword', reg, req.description]
            return true
          end
        end unless @list.nil?
      when 'domain_suffix'
        @list.each do |key|
          reg = /.*#{key}/
          if reg =~ req.only_host
            @matched_rule = ['domain_suffix', reg, req.description]
            return true
          end
        end unless @list.nil?
      when 'geoip'
        @list.each do |country_code|
          if !req.country_code.nil? && req.country_code.upcase == country_code.upcase
            @matched_rule = ['geoip', country_code, req.description]
            return true
          end
        end unless @list.nil?
      when 'ip_cidr'
        # FIXME https://www.altamiracorp.com/ parse rule spent 10s
        return false if req.ip_address.nil?

        reqip = begin
          IPAddress(req.ip_address)
        rescue => e
          Yyrp.logger.error "#{__FILE__} #{__LINE__} #{e}".colorize(:red)
          nil
        end
        return false if reqip.nil?

        req_net = IPAddr.new(req.ip_address)
        @list.each do |ic|
          ip = IPAddress(ic)
          # FIXME need a long time
          next if ip.prefix != reqip.prefix
          next if ip.octets[0] != reqip.octets[0]

          ip = IPAddr.new(ic)
          if ip.include?(req_net)
            @matched_rule = ['ip_cidr', ic, req.description]
            return true
          end
        end if !@list.nil? && !reqip.nil?
      when 'other'
        @matched_rule = ['other', nil, req.description]
        return true
      else
        Yyrp.logger.error "not support rule type: #{@type}".colorize(:red)
    end
    false
  end

  def adapter
    case @action
      when 'http'
        HttpAdapter
      when 'shadowsocks'
        ShadowsocksAdapter
      when 'direct'
        DirectAdapter
      when 'reject'
        nil
      when 'mitm'
        MitmAdapter
      when 'speed'
        ShadowsocksAdapter # FIXME
      else
        DirectAdapter
    end
  end
end
