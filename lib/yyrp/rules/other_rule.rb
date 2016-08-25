require_relative 'base_rule'

class OtherRule < BaseRule
  def initialize(type, action, adapter_name = nil)
    @adapter_name = adapter_name
    super(type, action)
  end
end