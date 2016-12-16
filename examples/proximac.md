# proximac

## Build with xcode

## Enable kext dev mode(OSX 10.10+) [more](https://developer.apple.com/library/content/documentation/Security/Conceptual/System_Integrity_Protection_Guide/ConfiguringSystemIntegrityProtection/ConfiguringSystemIntegrityProtection.html#//apple_ref/doc/uid/TP40016462-CH5-SW1)

```bash
# OSX 10.10
sudo nvram boot-args="kext-dev-mode=1"

# OSX 10.11+ go to Recovery Mode -> Terminal
csrutil status
csrutil enable --without kext --without debug
```

## Load kext

```bash
# load kext
kextstat | grep proximac
sudo chmod -R 755 proximac.kext
sudo chown -R root:wheel proximac.kext
sudo kextload proximac.kext
kextstat | grep proximac

sudo kextunload proximac.kext
```

## proximac.json

```json
{
    "local_port": 1080,
    "local_address": "127.0.0.1",
    "proximac_port": 8558,
    "VPN_mode": 1,
    "proxyapp_name": "ss-local"
}
```

## Run

```bash
# start socks 5 server
ss-local -c

proximac-cli start -c proximac.json

proximac-cli stop
```

## Log

Console -> system.log
