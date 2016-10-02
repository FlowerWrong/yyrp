require_relative 'base_domain_filter'

class DomainKeywordFilter < BaseDomainFilter
  def initialize(type, domain_keywords)
    super(type)
    @domain_keywords = domain_keywords
  end
end
