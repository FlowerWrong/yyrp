require_relative '../proxy/ssl_reverse_proxy'
require_relative '../certs/ca'
require_relative '../interception/handlers'

module Ritm
  module Proxy
    # Launches the Proxy server and the SSL Reverse Proxy with the given settings
    class Launcher
      # By default settings are read from Ritm::Configuration but you can override some via these named arguments:
      #   ssl_reverse_proxy_port [Fixnum]: the port where the reverse proxy for ssl traffic interception listens
      #   ca_crt_path [String]: the path to the certification authority certificate
      #   ca_key_path [String]: the path to the certification authority private key
      #   request_interceptor [Proc |request|]: the handler for request interception
      #   response_interceptor [Proc |request, response|]: the handler for response interception
      def initialize(**args)
        build_settings(**args)
        build_reverse_proxy(@ssl_proxy_host, @ssl_proxy_port, @request_interceptor, @response_interceptor)
      end

      # Starts the service (non blocking)
      def start_async
        @https.start_async
      end

      def start
        @https.start
      end

      # Stops the service
      def shutdown
        @https.shutdown
      end

      private

      def build_settings(**args)
        c = Ritm.conf
        @ssl_proxy_host = c.ssl_reverse_proxy.bind_address
        @ssl_proxy_port = args.fetch(:ssl_reverse_proxy_port, c.ssl_reverse_proxy.bind_port)
        @https_forward = "#{@ssl_proxy_host}:#{@ssl_proxy_port}"
        @request_interceptor = args[:request_interceptor] || DEFAULT_REQUEST_HANDLER
        @response_interceptor = args[:response_interceptor] || DEFAULT_RESPONSE_HANDLER

        crt_path = args.fetch(:ca_crt_path, c.ssl_reverse_proxy.ca.pem)
        key_path = args.fetch(:ca_key_path, c.ssl_reverse_proxy.ca.key)
        @certificate = ca_certificate(crt_path, key_path)
      end

      def build_reverse_proxy(_host, port, req_intercept, res_intercept)
        @https = Ritm::Proxy::SSLReverseProxy.new(port, @certificate,
                                                  request_interceptor: req_intercept,
                                                  response_interceptor: res_intercept)
      end

      def ca_certificate(pem, key)
        if pem.nil? || key.nil?
          Ritm::CA.create
        else
          Ritm::CA.load(File.read(pem), File.read(key))
        end
      end
    end
  end
end
