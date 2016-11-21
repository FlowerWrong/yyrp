$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'yyrp'
require 'yyrp/mitm/lib/ritm'

require 'webrick'
require 'webrick/https'

# cert_name = [
#   %w[CN 127.0.0.1],
# ]
#
# server = WEBrick::HTTPServer.new(:Port => 10001,
#                                  :SSLEnable => true,
#                                  :SSLCertName => cert_name)
Yyrp.set_config
cert = OpenSSL::X509::Certificate.new File.read Yyrp.config.servers['mitm']['ca_crt']
pkey = OpenSSL::PKey::RSA.new File.read Yyrp.config.servers['mitm']['ca_key']


default_vhost = 'localhost'

def gen_signed_cert(ca, common_name)
  cert = Ritm::Certificate.create(common_name)
  ca.sign(cert)
  cert
end

def vhost_settings(ca, hostname)
  cert = gen_signed_cert(ca, hostname)
  {
    ServerName: hostname,
    SSLEnable: true,
    SSLVerifyClient: OpenSSL::SSL::VERIFY_NONE,
    SSLPrivateKey: OpenSSL::PKey::RSA.new(cert.private_key),
    SSLCertificate: OpenSSL::X509::Certificate.new(cert.pem),
    SSLCertName: [['CN', hostname]]
  }
end

def ca_certificate(pem, key)
  if pem.nil? || key.nil?
    Ritm::CA.create
  else
    Ritm::CA.load(File.read(pem), File.read(key))
  end
end
ca = ca_certificate(Yyrp.config.servers['mitm']['ca_crt'], Yyrp.config.servers['mitm']['ca_key'])
server = Ritm::Proxy::CertSigningHTTPSServer.new(Port: 10001,
                                                 AccessLog: [],
                                                 Logger: WEBrick::Log.new(File.open(File::NULL, 'w')),
                                                 ca: ca,
                                                 **vhost_settings(ca, default_vhost))


server.mount '/', Ritm::RequestInterceptorServlet, DEFAULT_REQUEST_HANDLER, DEFAULT_RESPONSE_HANDLER

trap 'INT' do
  server.shutdown
end

server.start
