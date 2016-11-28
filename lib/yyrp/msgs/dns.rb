require 'singleton'
require 'resolv'
require 'awesome_print'

class DNS
  include Singleton
  attr_accessor :querys, :exception_domains, :dns_client

  def initialize
    @querys = []
    @exception_domains = []

    @dns_cache_timeout = Yyrp.config.servers['dns']['cache_timeout']

    timer = EventMachine::PeriodicTimer.new(@dns_cache_timeout) do
      ap @querys
      ap @exception_domains
      @querys = []
      @exception_domains = []
      Yyrp.logger.info 'querys and exception_domains cache have been cleanup'
    end

    @dns_client = Resolv::DNS.new(nameserver: Yyrp.config.servers['dns']['nameservers'])
    @dns_client.timeouts = Yyrp.config.servers['dns']['timeout']
  end

  def resolv(domain)
    # DNS cache
    return nil if @exception_domains.include?(domain)
    flag, domain_h = cached?(domain)
    return domain_h[:ip] if flag
    begin
      ip_address = @dns_client.getaddress(domain)
      ip_address = ip_address.to_s
      @querys << {domain: domain, ip: ip_address, count: 2}
      ip_address
    rescue => e
      Yyrp.logger.error "#{__FILE__} #{__LINE__} #{domain} #{e}"
      @exception_domains.push domain
      nil
    end
  end

  def cached?(domain)
    @querys.each do |h|
      if h[:domain] == domain
        h[:count] += 1
        return [true, h]
      end
    end
    [false, nil]
  end
end
