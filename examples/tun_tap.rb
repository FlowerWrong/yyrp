# NOTE only work for linux
require 'rb_tuntap'
require 'packetfu'

DEV_NAME = 'tun'
DEV_ADDR = '192.168.192.168'

STDOUT.puts("** Opening tun device as #{DEV_NAME}")
tun = RbTunTap::TunDevice.new(DEV_NAME)
tun.open(false)

STDOUT.puts("** Assigning ip #{DEV_ADDR} to device")
tun.addr = DEV_ADDR
tun.netmask = "255.255.255.0"
tun.up

STDOUT.puts("** Interface stats (as seen by ifconfig)")
STDOUT.puts(`ifconfig #{DEV_NAME}`)

sleep 5

bytes = tun.to_io.sysread(tun.mtu)
eth = PacketFu::EthPacket.new
eth.payload = bytes
STDOUT.puts PacketFu::ICMPPacket.new.read(eth.to_s)

STDOUT.puts("** Bringing down and closing device")
tun.down
tun.close
