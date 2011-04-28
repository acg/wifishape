#!/bin/sh

# COMMENTED OUT
# here's how you would classify packets with tc directly, rather than
# using iptables to mark them...

# high priority / interactive traffic

# all icmp
# $u32 match ip protocol 1 0xff flowid 1:10
# dns
# $u32 match ip protocol 17 0xff match ip $portmatch 53 0xffff flowid 1:10
# dhcp
# $u32 match ip protocol 17 0xff match ip $portmatch 67 0xffff flowid 1:10
# ssh
# $u32 match ip protocol 6 0xff match ip $portmatch 22 0xffff flowid 1:10
# telnet 
# $u32 match ip protocol 6 0xff match ip $portmatch 23 0xffff flowid 1:10
# irc
# $u32 match ip protocol 6 0xff match ip $portmatch 6667 0xffff flowid 1:10
# ntp 
# $u32 match ip protocol 6 0xff match ip $portmatch 123 0xffff flowid 1:10

# bulk traffic 1

# www
# $u32 match ip protocol 6 0xff match ip $portmatch 80 0xffff flowid 1:11
# ssl
# $u32 match ip protocol 6 0xff match ip $portmatch 443 0xffff flowid 1:11
# ftp
# $u32 match ip protocol 6 0xff match ip $portmatch 21 0xffff flowid 1:11
# cvs
# $u32 match ip protocol 6 0xff match ip $portmatch 2401 0xffff flowid 1:11

# everything else by default goes into the crap bucket (bulk traffic 2)

