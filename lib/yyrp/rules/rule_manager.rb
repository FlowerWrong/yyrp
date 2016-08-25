require 'singleton'

require_relative 'domain_rule'
require_relative 'domain_keyword_rule'
require_relative 'domain_suffix_rule'
require_relative 'ip_cidr_rule'
require_relative 'other_rule'
require_relative 'geoip_rule'

require_relative '../config'

class RuleManager
  include Singleton
  attr_accessor :rules

  def adapter(request)
    rules.each do |rule|
      return [rule.adapter, rule.adapter_name] if rule.match(request)
    end
  end

  def rules
    @rules = []
    Yyrp.config.rules.each do |r_h|
      rule = case r_h['type']
               when 'domain'
                 DomainRule.new('domain', r_h['action'], r_h['domains'], r_h['adapter_name'])
               when 'domain_keyword'
                 DomainKeywordRule.new('domain_keyword', r_h['action'], r_h['domain_keywords'], r_h['adapter_name'])
               when 'domain_suffix'
                 DomainSuffixRule.new('domain_suffix', r_h['action'], r_h['domain_suffixs'], r_h['adapter_name'])
               when 'geoip'
                 GeoipRule.new('geoip', r_h['action'], r_h['geoips'], r_h['adapter_name'])
               when 'ip_cidr'
                 IpCidrRule.new('ip_cidr', r_h['action'], r_h['ip_cidrs'], r_h['adapter_name'])
               when 'other'
                 OtherRule.new('other', r_h['action'], r_h['adapter_name'])
               else
                 p 'not support rule type'
                 nil
             end
      @rules << rule unless rule.nil?
    end
    @rules
  end
end