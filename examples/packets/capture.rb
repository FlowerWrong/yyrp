require 'packetfu'
include PacketFu

def get_capture(iface,filter)
  cap = Capture.new(:iface=>iface, :start=>true,
                  :filter=>filter)
  cap.stream.each do |pkt|
    next unless TCPPacket.can_parse?(pkt)
    t_stamp  = Time.now.strftime("%Y-%m-%d %H:%M:%S.%6N")
    tcp_packet = TCPPacket.parse(pkt)
    src_mac = EthHeader.str2mac(tcp_packet.eth_src)
    dst_mac = EthHeader.str2mac(tcp_packet.eth_dst)
    src_ip = IPHeader.octet_array(tcp_packet.ip_src).join('.')
    dst_ip = IPHeader.octet_array(tcp_packet.ip_dst).join('.')
    src_port = tcp_packet.tcp_src
    dst_port = tcp_packet.tcp_dst
    puts "time:#{t_stamp},src_mac:#{src_mac},dst_mac:#{dst_mac},src_ip:#{src_ip},dst_ip:#{dst_ip},src_port:#{src_port},dst_port:#{dst_port}"
  end

end


if $0 == __FILE__
  iface = ARGV[0]
  filter = ARGV[1]
  get_capture(iface, filter)
end
