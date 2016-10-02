require_relative 'base_domain_filter'

class DomainFilter < BaseDomainFilter
  def initialize(type, domains)
    super(type)
    @domains = domains
  end
end
