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
      if rule.match(request)
        case rule.type
        when 'geoip'
          Yyrp.logger.info "Rule match is #{rule.matched_rule}; country_code: #{request.country_code}"
        else
          Yyrp.logger.info "Rule match is #{rule.matched_rule}"
        end
        return [rule.adapter, rule.adapter_name]
      end
    end
    [nil, nil]
  end

  def rules
    @rules = []
    Yyrp.config.rules.each do |r_h|
      rule = case r_h['type']
               when 'domain'
                 DomainRule.new('domain', r_h['action'], r_h['list'], r_h['adapter_name'])
               when 'domain_keyword'
                 DomainKeywordRule.new('domain_keyword', r_h['action'], r_h['list'], r_h['adapter_name'])
               when 'domain_suffix'
                 DomainSuffixRule.new('domain_suffix', r_h['action'], r_h['list'], r_h['adapter_name'])
               when 'geoip'
                 GeoipRule.new('geoip', r_h['action'], r_h['list'], r_h['adapter_name'])
               when 'ip_cidr'
                 IpCidrRule.new('ip_cidr', r_h['action'], r_h['list'], r_h['adapter_name'])
               when 'other'
                 OtherRule.new('other', r_h['action'], r_h['adapter_name'])
               else
                 Yyrp.logger.error 'not support rule type'
                 nil
             end
      @rules << rule unless rule.nil?
    end
    @rules
  end
end
