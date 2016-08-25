require_relative 'base_rule'

class BaseDomainRule < BaseRule
  def initialize(type, action)
    raise("Type #{type} not support for base domain rule") unless types.include?(type)
    super(type, action)
  end

  def types
    %w(domain domain_keyword domain_suffix)
  end
end