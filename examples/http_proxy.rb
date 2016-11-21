# https://www.fedux.org/articles/2015/04/11/setup-a-proxy-with-ruby.html
require 'webrick'
require 'webrick/httpproxy'
require 'awesome_print'

# Apache compatible Password manager
htpasswd = WEBrick::HTTPAuth::Htpasswd.new File.expand_path('../httpasswd', __FILE__)
# Create entry with username and password, the password is "crypt" encrypted
htpasswd.set_passwd 'Proxy Realm', 'yang', 'pass' # = Base64.encode64('yang:pass')
# Write file to disk
htpasswd.flush

# Authenticator
authenticator = WEBrick::HTTPAuth::ProxyBasicAuth.new(
  Realm: 'Proxy Realm',
  UserDB: htpasswd
)

handler = proc do |req, res|
  ap req
end

proxy = WEBrick::HTTPProxyServer.new Port: 10000, ProxyContentHandler: handler, ProxyAuthProc: authenticator.method(:authenticate).to_proc

trap 'INT'  do proxy.shutdown end
trap 'TERM' do proxy.shutdown end

proxy.start

# curl -x localhost:10000 -U yang:pass liveneeq.com
# curl -k -x localhost:10000 https://tower.im
