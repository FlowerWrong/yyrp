# README

## Get start

```bash
brew install libmaxminddb
bundle install

rake down_mmdb
rake unzip_mmdb

cp config.example.json config.json
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
* [ ] reload config.json
* [ ] log
* [ ] packet filter: header and body(http/https support)
* [ ] DNS server
* [ ] speed adapter
* [ ] http/https adapter
* [ ] command line tools
* [ ] websocket for view
* [ ] tun2socks support with iptables
* [ ] kcp support
* [ ] v2ray support
* [ ] IPV6 support
* [ ] socks5 proxy server with auth, ip, udp support
* [ ] more shadowsocks method support

## Known bugs

* [ ] [altamiracorp.com](https://www.altamiracorp.com/): DNS resolve bug. `Resolv.getaddress` in request and `EventMachine::connect` in relay.
* [x] safari not working
* [ ] ip support: 123.56.230.53:29231
* [ ] 网易云音乐 search not work
* [ ] mitm can not handle http, https only

## Proxy

#### Http/https

* squid + [stunnel](https://www.stunnel.org)
* [tinyproxy](https://github.com/tinyproxy/tinyproxy) + [stunnel](https://www.stunnel.org)

#### Shadowsocks

* [My shadowsocks server](https://github.com/FlowerWrong/yyrp/blob/master/lib/yyrp/shadowsocks/server.rb)
