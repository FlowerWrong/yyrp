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
  attr_accessor :cached_matches

  def adapter(request)
    cache = @cached_matches[request.host]
    return [cache[:adapter], cache[:adapter_name]] if cache && cache.is_a?(Hash)
    @rules.each do |rule|
      time_start = Time.now
      if rule.match(request)
        case rule.type
        when 'geoip'
          Yyrp.logger.info "Rule match is #{rule.matched_rule}; country_code: #{request.country_code}"
        else
          Yyrp.logger.info "Rule match is #{rule.matched_rule}"
        end
        h = {
          domain: request.host,
          adapter: rule.adapter,
          adapter_name: rule.adapter_name,
          rule: rule.type,
          ip_address: request.ip_address,
          country_code: request.country_code
        }
        @cached_matches[request.host] = h unless request.host.nil?

        case rule.type
        when 'geoip', 'other', 'ip_cidr'
          @need_to_config_rules << h
        end
        ap @need_to_config_rules
        return [rule.adapter, rule.adapter_name]
      else
        time_end = Time.now
        time = time_end - time_start
        if time > 1
          Yyrp.logger.error "Parse rule #{rule.description} : #{request.description} which not match spent #{time.to_s}s".colorize(:red)
        end
      end
    end
    [nil, nil]
  end

  def set_cached_matches
    @cached_matches = {}
    @need_to_config_rules = []
  end

  def set_rules
    set_cached_matches
    @rules = []
    Yyrp.logger.info 'Rule manager rules and cached_matches have beed seted'
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
    # @rules
  end
end
