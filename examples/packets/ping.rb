$LOAD_PATH.unshift File.expand_path('../../../lib', __FILE__)
require 'yyrp'
require 'yyrp/utils/ping'

good = 'liveneeq.com'
ss = '47.90.32.252'
bad  = 'foo.bar.baz'
p Ping.sys_ping(good)
p Ping.sys_ping(ss)
p Ping.sys_ping(bad)
