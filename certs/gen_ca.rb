$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'yyrp'
require 'yyrp/mitm/lib/ritm/certs/ca'

ca = Ritm::CA.create common_name: 'InsecureCA'

File.write('insecure_ca.crt', ca.pem)
File.write('insecure_ca.key', ca.private_key.to_s)