require_relative 'base_domain_filter'

class DomainSuffixFilter < BaseDomainFilter
  def initialize(type, domain_suffixs)
    super(type)
    @domain_suffixs = domain_suffixs
  end
end
