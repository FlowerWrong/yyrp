require 'webrick'
require 'webrick/https'

# cert_name = [
#   %w[CN 127.0.0.1],
# ]
#
# server = WEBrick::HTTPServer.new(:Port => 10001,
#                                  :SSLEnable => true,
#                                  :SSLCertName => cert_name)


cert = OpenSSL::X509::Certificate.new File.read "/Users/kingyang/dev/ruby/gems/yyrp/certs/insecure_ca.crt"
pkey = OpenSSL::PKey::RSA.new File.read '/Users/kingyang/dev/ruby/gems/yyrp/certs/insecure_ca.key'

server = WEBrick::HTTPServer.new(:Port => 10001,
                                 :SSLEnable => true,
                                 :SSLCertificate => cert,
                                 :SSLPrivateKey => pkey)

trap 'INT' do server.shutdown end

server.start