require 'singleton'

require_relative 'domain_filter'
require_relative 'domain_keyword_filter'
require_relative 'domain_suffix_filter'
# require_relative 'ip_cidr_filter'
# require_relative 'other_filter'
# require_relative 'geoip_filter'

class FilterManager
  include Singleton
  attr_accessor :filters

  def match(request)
    @filters.each do |filter|
      if filter.match(request)
        case filter.type
        when 'geoip'
          Yyrp.logger.info "Filter match is #{filter.matched_filter}; country_code: #{request.country_code}"
        else
          Yyrp.logger.info "Filter match is #{filter.matched_filter}"
        end
        return true
      end
    end
    false
  end

  def set_filters
    @filters = []
    Yyrp.logger.info 'Filter manager filters have beed seted'
    Yyrp.config.filters.each do |filter_h|
      filter = case filter_h['type']
                 when 'domain'
                   DomainFilter.new('domain', filter_h['list'])
                 when 'domain_keyword'
                   DomainKeywordFilter.new('domain_keyword', filter_h['list'])
                 when 'domain_suffix'
                   DomainSuffixFilter.new('domain_suffix', filter_h['list'])
                #  when 'geoip'
                #    GeoipFilter.new('geoip', filter_h['list'])
                #  when 'ip_cidr'
                #    IpCidrFilter.new('ip_cidr', filter_h['list'])
                #  when 'other'
                #    OtherFilter.new('other')
                 else
                   Yyrp.logger.error 'not support filter type'
                   nil
               end
      @filters << filter unless filter.nil?
    end
  end
end
