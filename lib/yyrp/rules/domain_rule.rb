require_relative 'base_domain_rule'

class DomainRule < BaseDomainRule
  def initialize(type, action, domains, adapter_name = nil)
    @adapter_name = adapter_name
    super(type, action)
    @domains = domains
  end
end