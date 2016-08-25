require 'dot_hash'
require 'set'

module Ritm
  # Global Ritm settings
  class Configuration
    DEFAULT_SETTINGS = {
      proxy: {
        bind_address: '127.0.0.1',
        bind_port: 8080
      },

      ssl_reverse_proxy: {
        bind_address: '127.0.0.1',
        bind_port: 7779,
        ca: {
          pem: nil,
          key: nil
        }
      },

      intercept: {
        enabled: true,
        request: {
          add_headers: {},
          strip_headers: [/proxy-*/],
          unpack_gzip_deflate: true,
          update_content_length: true
        },
        response: {
          add_headers: { 'connection' => 'close' },
          strip_headers: ['strict-transport-security'],
          unpack_gzip_deflate: true,
          update_content_length: true
        },
        process_chunked_encoded_transfer: true
      },

      misc: {
        ssl_pass_through: []
      }

    }.freeze

    def initialize(settings = {})
      reset(settings)
    end

    def reset(settings = {})
      settings = DEFAULT_SETTINGS.merge(settings)
      @settings = settings.to_properties
    end

    def method_missing(m, *args, &block)
      if @settings.respond_to?(m)
        @settings.send(m, *args, &block)
      else
        super
      end
    end

    def respond_to_missing?(method_name, _include_private = false)
      @settings.respond_to?(method_name) || super
    end

    # Re-enable interception
    def enable
      @settings.intercept[:enabled] = true
    end

    # Disable interception
    def disable
      @settings.intercept[:enabled] = false
    end
  end
end
