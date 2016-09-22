require 'ipaddress'
require 'resolv'
require 'maxmind_geoip2'

require_relative '../config'

class Request
  attr_accessor :host, :only_host, :port, :ip_address, :headers, :body, :method, :http_version, :request_url, :protocol
  attr_reader :country_code
  def initialize(host, port, headers = {})
    @host = host # maybe domain, maybe ip
    @port = port
    @only_host = nil # must be domain, or nil
    @headers = headers
  end

  def description
    "host: #{host}; port: #{port}; ip_address: #{ip_address}, method: #{method}; http_version: #{http_version}"
  end

  def only_host
    IPAddress.valid?(@host) ? nil : @host
  end

  # ip
  def ip_address
    if IPAddress.valid?(@host)
      @host
    else
      @only_host = @host
      # FIXME no address for api.coderwall.com (Resolv::ResolvError)
      begin
        Resolv.getaddress(@only_host)
      rescue => e
        Yyrp.logger.error e
        nil
      end
    end
  end

  def country_code
    # undefined method `[]' for nil:NilClass
    return nil if ip_address.nil?
    MaxmindGeoIP2.file(Yyrp.config.servers['mmdb']['path'])
    res = MaxmindGeoIP2.locate(ip_address) if ip_address
    if res.nil? || ip_address.nil?
      nil
    else
      res['country_code']
    end
  end
end
