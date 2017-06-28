#!/bin/bash

echo `date`
echo "Setting FakeDNS Servers"
echo "nameserver 10.192.0.1"  > /etc/resolv.conf
