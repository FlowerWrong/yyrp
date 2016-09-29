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
ruby proxy.rb # only http/https socks proxy
ruby mitm.rb # mitm server for https packet capture
ruby ss.rb # shadowsocks server
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
* [ ] speed adapter: simple implement with ping, only for proxy, not direct
* [ ] http/https adapter
* [ ] command line tools
* [ ] websocket for view
* [ ] tun2socks support with iptables
* [ ] kcp support
* [ ] v2ray support
* [ ] IPV6 support
* [ ] socks5 proxy server with auth support
* [ ] more shadowsocks method support

## Shadowsocks server TODO

* [ ] onetime authentication
* [ ] autoban
* [ ] download big file [memory bug](http://sen.github.io/shadowsocks/2014/01/18/shadowsocks-event.html)

## Known bugs

* [x] [altamiracorp.com](https://www.altamiracorp.com/): DNS resolve bug. `Resolv.getaddress` in request and `EventMachine::connect` in relay.
* [x] safari not working
* [x] ip support: 123.56.230.53:29231
* [ ] 网易云音乐 search not work, download file with http?
* [ ] mitm can not handle http, https only
* [ ] DNS 解析失败会导致卡死
* [ ] ip cidr cal a long time

## Proxy

#### Http/https

* squid + [stunnel](https://www.stunnel.org)
* [tinyproxy](https://github.com/tinyproxy/tinyproxy) + [stunnel](https://www.stunnel.org)

#### Shadowsocks

* [My shadowsocks server](https://github.com/FlowerWrong/yyrp/blob/master/lib/yyrp/shadowsocks/server.rb)
