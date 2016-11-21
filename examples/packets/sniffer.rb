require 'packetfu'

# rvmsudo ruby examples/packets/sniffer.rb

puts "Simple sniffer for PacketFu #{PacketFu.version}"
include PacketFu
iface = ARGV[0] || PacketFu::Utils.default_int

def sniff(iface)
  cap = Capture.new(:iface => iface, :start => true)
  cap.stream.each do |p|
    pkt = Packet.parse p
    if pkt.is_ip?
      next if pkt.ip_saddr == Utils.ifconfig(iface)[:ip_saddr]
      packet_info = [pkt.ip_saddr, pkt.ip_daddr, pkt.size, pkt.proto.last]
      puts "%-15s -> %-15s %-4d %s" % packet_info
    end
  end
end

sniff(iface)
