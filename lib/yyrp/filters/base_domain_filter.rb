require_relative 'base_filter'

class BaseDomainFilter < BaseFilter
  def initialize(type)
    raise("Type #{type} not support for base domain filter") unless types.include?(type)
    super(type)
  end

  def types
    %w(domain domain_keyword domain_suffix)
  end
end
