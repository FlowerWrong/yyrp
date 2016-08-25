require_relative 'base_rule'

class GeoipRule < BaseRule
  def initialize(type, action, geoips, adapter_name = nil)
    @adapter_name = adapter_name
    super(type, action)
    @geoips = geoips
  end
end