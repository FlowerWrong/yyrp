# README

## Get start

```bash
brew install libmaxminddb
bundle install

rake down_mmdb
rake unzip_mmdb

# Optional, it is for mitm
rake gen_ca
rake install_ca

cp config.example.json config.json

cd examples
ruby proxy.rb # only http/https and socks 5 proxy
ruby mitm.rb # mitm server for https packet capture
ruby ss.rb # shadowsocks server
```

## Settings

#### Terminal setting in .zshrc or .bashrc ...

```bash
function setp(){
  export http_proxy='http://127.0.0.1:7777'
  export https_proxy='http://127.0.0.1:7777'
}

function unsetp(){
  unset http_proxy
  unset https_proxy
}
```

#### OSX NetWork Setting(It is not work for terminal)

![OSX NetWork Setting](https://raw.githubusercontent.com/FlowerWrong/yyrp/master/screenshots/osx_network_setting.png)

```bash
# ignore proxy
127.0.0.1, 192.168.0.0/16, 10.0.0.0/8, 172.16.0.0/12, 100.64.0.0/10, localhost, *.local, 0.0.0.0
```

## Idea form

* [NEKit](https://github.com/zhuhaow/NEKit)
* [surge for Mac](http://nssurge.com/)
* [charles](https://www.charlesproxy.com/)
* [privoxy](https://www.privoxy.org/)
* [ritm](https://github.com/argos83/ritm): Man-in-the-middle attack

## Test

```bash
rake
```

## Rules, see more [config.example.json](https://github.com/FlowerWrong/yyrp/blob/master/config.example.json)

* There are 4 adapters, `direct`, `mitm`, `http(https)` and `shadowsocks`.
* There are 6 actions, `http(https):http_adapter`, `shadowsocks:shadowsocks_adapter`, `direct:direct_adapter`, `speed:select fastest adapters`, `mitm:mitm_adapter`, and `reject:just close this socket`.
* There are 6 rule types, `geoip`, `domain`, `domain_keyword`, `domain_suffix`, `ip_cidr` and `other`, note: rules are in order.
* Filters is for packet capture, just work for http. if it is https, please use `mitm` action

## Note

* If you are using `https adapter`, the auth will be ignore

## Todo

* [x] http/https proxy server
* [x] socks5 proxy server
* [x] direct adapter
* [x] shadowsocks adapter
* [x] shadowsocks server
* [x] rule manager
* [x] [geolite2](https://dev.maxmind.com/zh-hans/geoip/geoip2/geolite2-%E5%BC%80%E6%BA%90%E6%95%B0%E6%8D%AE%E5%BA%93/) support
* [x] reject, but in browser has some bug???
* [x] packet capture: http/https support
* [x] reload config.json
* [ ] yaml config support
* [ ] surge config support
* [x] log
* [ ] packet filter: header and body(http/https support)
* [ ] DNS server
* [x] DNS cache
* [ ] speed adapter: simple implement with ping, only for proxy, not direct
* [x] http/https adapter
* [ ] command line tools
* [ ] websocket for view
* [x] websocket proxy support
* [ ] websocket-extensions support
* [ ] tun2socks support with iptables
* [ ] kcp support
* [ ] v2ray support
* [x] IPV6 support
* [ ] socks5 proxy server with auth support
* [ ] more shadowsocks method support
* [x] http multipart/form-data support
* [x] `x-forwarded-for` and `x-real-ip`
* [x] local https proxy support(so hard)

## Shadowsocks server TODO

* [ ] onetime authentication
* [ ] autoban
* [ ] download big file [memory bug](http://sen.github.io/shadowsocks/2014/01/18/shadowsocks-event.html)

## Known bugs

* [x] [altamiracorp.com](https://www.altamiracorp.com/): DNS resolve bug. `Resolv.getaddress` in request and `EventMachine::connect` in relay.
* [x] safari not working
* [x] ip support: 123.56.230.53:29231
* [ ] 网易云音乐 search not work, download file with http?
* [x] mitm can not handle http, https only
* [x] DNS ResolvError may break proxy
* [x] ip cidr cal a long time
* [x] use proxy when <Resolv::ResolvError> no address for api.smoot.apple.com.cn
* [x] weixin upload image http proxy only

## Proxy

#### Http/https

* squid + [stunnel](https://www.stunnel.org)
* [tinyproxy](https://github.com/tinyproxy/tinyproxy) + [stunnel](https://www.stunnel.org)
* [Squid SSL 相关特性总结](https://www.zybuluo.com/delight/note/2649)

#### Shadowsocks

* [My shadowsocks server](https://github.com/FlowerWrong/yyrp/blob/master/lib/yyrp/shadowsocks/server.rb)

## Reference

* [ettercap](https://github.com/Ettercap/ettercap)
* [libpcap](http://www.tcpdump.org/pcap.html)
* [iperf3](https://iperf.fr/)
