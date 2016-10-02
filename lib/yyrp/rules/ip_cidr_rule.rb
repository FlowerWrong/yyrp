require_relative 'base_rule'

class IpCidrRule < BaseRule
  def initialize(type, action, ip_cidrs, adapter_name = nil)
    @adapter_name = adapter_name
    super(type, action)
    @list = ip_cidrs
  end
end
