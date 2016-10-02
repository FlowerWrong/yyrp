require 'ipaddress'

class BaseFilter
  attr_accessor :type, :domains, :domain_keywords, :domain_suffixs, :geoips, :ip_cidrs, :matched_filter
  def initialize(type)
    raise("Type #{type} not support for this filter") unless types.include?(type)
    @type = type
  end

  def types
    %w(domain domain_keyword domain_suffix geoip ip_cidr)
  end

  def match(req)
    case @type
      when 'domain'
        @domains.each do |d|
          if d == req.only_host
            @matched_filter = ['domain', d, req.description]
            return true
          end
        end unless @domains.nil?
      when 'domain_keyword'
        @domain_keywords.each do |key|
          reg = /.*#{key}.*/
          if reg =~ req.only_host
            @matched_filter = ['domain_keyword', reg, req.description]
            return true
          end
        end unless @domain_keywords.nil?
      when 'domain_suffix'
        @domain_suffixs.each do |key|
          reg = /.*#{key}/
          if reg =~ req.only_host
            @matched_filter = ['domain_suffix', reg, req.description]
            return true
          end
        end unless @domain_suffixs.nil?
      # when 'geoip'
      #   @geoips.each do |country_code|
      #     if !req.country_code.nil? && req.country_code.upcase == country_code.upcase
      #       @matched_filter = ['geoip', country_code, req.description]
      #       return true
      #     end
      #   end unless @geoips.nil?
      # when 'ip_cidr'
      #   # FIXME https://www.altamiracorp.com/
      #   return false if req.ip_address.nil?
      #   reqip = begin
      #     IPAddress(req.ip_address)
      #   rescue => e
      #     Yyrp.logger.error e
      #     nil
      #   end # FIXME `parse': Unknown IP Address  (ArgumentError)
      #   return false if reqip.nil?
      #   reqip_str = reqip.to_string
      #
      #   @ip_cidrs.each do |ic|
      #     ip = IPAddress(ic)
      #     # FIXME need a long time
      #     next if ip.prefix != reqip.prefix
      #     next if ip.octets[0] != reqip.octets[0]
      #     ip.each_host do |ip_addr|
      #       if ip_addr.to_string == reqip_str
      #         @matched_filter = ['ip_cidr', ic, req.description]
      #         return true
      #       end
      #     end unless ip.nil?
      #   end if !@ip_cidrs.nil? && !reqip.nil?
      # when 'other'
      #   @matched_filter = ['other', nil, req.description]
      #   return true
      else
        Yyrp.logger.error "not support filter type: #{@type}"
    end
    false
  end
end
