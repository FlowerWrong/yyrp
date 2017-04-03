#!/bin/bash
# 后面将会用ss-tunnel开启本地dns解析服务，所以将本地dns的udp请求转发到pdnsd的dns端口
# 至于为什么多此一举，而不直接将pdnsd的本地端口设置为53，是因为53端口已经被污染了，所以通过此方法来欺骗GFW
iptables -t nat -A OUTPUT -p udp --dport 53 -j DNAT --to 127.0.0.1:10053
