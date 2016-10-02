require_relative 'base_domain_rule'

class DomainSuffixRule < BaseDomainRule
  def initialize(type, action, domain_suffixs, adapter_name = nil)
    @adapter_name = adapter_name
    super(type, action)
    @list = domain_suffixs
  end
end
