# Only work for linux

## Get start

get [china_ip_list](https://github.com/17mon/china_ip_list)

```bash
sudo systemctl start pdnsd
sudo pdnsd-ctl status
sudo ./up.sh SOCKS_SERVER GATEWAY_IP
```

## Tools

* [iptables](https://www.netfilter.org/downloads.html)
* [ipset](http://ipset.netfilter.org/)
* [iprange](https://github.com/firehol/iprange)
