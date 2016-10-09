require 'whirly'
require_relative 'lib/yyrp/utils/download_progress'

mmdb_gz_file = File.expand_path('./mmdb/GeoLite2-Country.mmdb.gz', File.dirname(__FILE__))
mmdb_file = File.expand_path('./mmdb/GeoLite2-Country.mmdb', File.dirname(__FILE__))
task :down_mmdb do
  Whirly.start do
    Whirly.status = 'Start download mmdb'
    url = 'http://geolite.maxmind.com/download/geoip/database/GeoLite2-Country.mmdb.gz'
    down(url, mmdb_gz_file)
    Whirly.status = 'MMDB downloaded'
  end
end

require 'zlib'
task :unzip_mmdb do
  Whirly.start do
    Whirly.status = 'Start unzip mmdb'

    Zlib::GzipReader.open(mmdb_gz_file) do | input_stream |
      File.open(mmdb_file, 'w') do |output_stream|
        IO.copy_stream(input_stream, output_stream)
      end
    end
  end
end

require_relative 'lib/yyrp/mitm/lib/ritm/certs/ca'
task :gen_ca do
  Whirly.start do
    Whirly.status = 'Start generate mitm CA'
    ca = Ritm::CA.create common_name: 'InsecureCA'

    File.write('certs/insecure_ca.crt', ca.pem)
    File.write('certs/insecure_ca.key', ca.private_key.to_s)
  end
end

require 'os'
task :install_ca do
  if OS.mac?
    sh 'sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain ./certs/insecure_ca.crt'
  else
    Whirly.start do
      Whirly.status = 'No support for your system'
    end
  end
end
