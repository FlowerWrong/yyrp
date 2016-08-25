require_relative 'base_domain_rule'

class DomainKeywordRule < BaseDomainRule
  def initialize(type, action, domain_keywords, adapter_name = nil)
    @adapter_name = adapter_name
    super(type, action)
    @domain_keywords = domain_keywords
  end
end