# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'yyrp/version'

Gem::Specification.new do |spec|
  spec.name          = "yyrp"
  spec.version       = Yyrp::VERSION
  spec.authors       = ["yang"]
  spec.email         = ["yangkang@liveneeq.com"]

  spec.summary       = %q{A http/https, socks proxy server, a mitm server and a shadowsocks server with rules}
  spec.description   = %q{A http/https, socks proxy server, a mitm server and a shadowsocks server with rules}
  spec.homepage      = "http://www.liveneeq.com"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'eventmachine'
  spec.add_dependency 'http_parser.rb'
  spec.add_dependency 'uuid'
  spec.add_dependency 'ipaddress'
  spec.add_dependency 'ruby-progressbar'
  spec.add_dependency 'awesome_print'
  spec.add_dependency 'activesupport'
  spec.add_dependency 'maxmind_geoip2'
  spec.add_dependency 'os'
  # spec.add_dependency 'packetfu'
  spec.add_dependency 'net-ping'

  spec.add_runtime_dependency 'faraday'
  spec.add_runtime_dependency 'webrick'
  spec.add_runtime_dependency 'certificate_authority'
  spec.add_runtime_dependency 'dot_hash'

  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"
end
