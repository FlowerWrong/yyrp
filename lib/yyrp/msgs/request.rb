require 'ipaddress'
require 'resolv'
require 'maxminddb'

require_relative '../config'

require_relative 'dns'

class Request
  attr_accessor :host, :only_host, :port, :ip_address, :headers, :body, :method, :http_version, :request_url, :protocol, :country_code
  def initialize(host, port, headers = {})
    @host = host # maybe domain, maybe ip
    @port = port
    @only_host = nil # must be domain, or nil
    @headers = headers
  end

  def description
    "host: #{host}; port: #{port}; method: #{method}; http_version: #{http_version}"
  end

  def only_host
    return @only_host if @only_host
    @only_host = IPAddress.valid?(@host) ? nil : @host
  end

  # ip
  def ip_address
    return @ip_address if @ip_address
    if IPAddress.valid?(@host)
      @ip_address = @host
    else
      @only_host = @host
      @ip_address = DNS.instance.resolv(@only_host)
    end
    @ip_address
  end

  def country_code
    return @country_code if @country_code
    time_start = Time.now
    return nil if ip_address.nil?

    db = MaxMindDB.new(Yyrp.config.servers['mmdb']['path'])
    begin
      res = db.lookup(ip_address) if ip_address
      @country_code = (res.nil? || ip_address.nil? || !res.found?) ? nil : res.country.iso_code
      time_end = Time.now
      time = time_end - time_start
      if time > 1
        Yyrp.logger.error '----------------------------------------------------'
        Yyrp.logger.error "Parse country_code #{ip_address} country_code is #{@country_code} spent #{time.to_s}s"
      end
    rescue => e
      Yyrp.logger.error "#{__FILE__} #{__LINE__} #{e}"
      return nil
    end
    @country_code
  end
end
