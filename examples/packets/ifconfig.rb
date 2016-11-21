require 'packetfu'
require 'awesome_print'

# rvmsudo ruby examples/packets/ifconfig.rb

iface = ARGV[0] || PacketFu::Utils.default_int
config = PacketFu::Utils.ifconfig(iface)
print "#{RUBY_PLATFORM} => "
ap config
