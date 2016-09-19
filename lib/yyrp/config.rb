require 'logging'
require 'active_support/configurable'

module Yyrp
  class Config
    include ActiveSupport::Configurable
    config_accessor :servers, :adapters, :rules, :logger
  end

  def self.configure(&block)
    yield config
  end

  def self.config
    @config ||= Config.new
  end

  def self.logger
    @config.logger
  end
end
