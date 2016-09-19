require 'ipaddress'

require_relative '../adapters/direct_adapter'
require_relative '../adapters/http_adapter'
require_relative '../adapters/shadowsocks_adapter'

class BaseRule
  attr_accessor :action, :type, :domains, :domain_keywords, :domain_suffixs, :geoips, :ip_cidrs, :adapter_name, :matched_rule
  def initialize(type, action)
    raise("Type #{type} not support for this rule") unless types.include?(type)
    raise("Action #{action} not support for this rule") unless actions.include?(action)
    @type = type
    @action = action
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
        @domains.each do |d|
          if d == req.only_host
            @matched_rule = ['domain', d, req.description]
            return true
          end
        end unless @domains.nil?
      when 'domain_keyword'
        @domain_keywords.each do |key|
          reg = /.*#{key}.*/
          if reg =~ req.only_host
            @matched_rule = ['domain_keyword', reg, req.description]
            return true
          end
        end unless @domain_keywords.nil?
      when 'domain_suffix'
        @domain_suffixs.each do |key|
          reg = /.*#{key}/
          if reg =~ req.only_host
            @matched_rule = ['domain_suffix', reg, req.description]
            return true
          end
        end unless @domain_suffixs.nil?
      when 'geoip'
        @geoips.each do |country_code|
          if !req.country_code.nil? && req.country_code.upcase == country_code.upcase
            @matched_rule = ['geoip', country_code, req.description]
            return true
          end
        end unless @geoips.nil?
      when 'ip_cidr'
        # FIXME https://www.altamiracorp.com/
        return false if req.ip_address.nil?
        reqip = IPAddress(req.ip_address)
        return false if reqip.nil?
        reqip_str = reqip.to_string

        @ip_cidrs.each do |ic|
          ip = IPAddress(ic)
          # FIXME need a long time
          next if ip.prefix != reqip.prefix
          next if ip.octets[0] != reqip.octets[0]
          ip.each_host do |ip_addr|
            if ip_addr.to_string == reqip_str
              @matched_rule = ['ip_cidr', ic, req.description]
              return true
            end
          end unless ip.nil?
        end if !@ip_cidrs.nil? && !reqip.nil?
      when 'other'
        @matched_rule = ['other', nil, req.description]
        return true
      else
        p "not support rule type: #{@type}"
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
