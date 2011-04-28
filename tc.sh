#!/bin/bash

set -v

# defaults
default_linkspeed=300 # in kbit/s
default_linktype="outward"

usage()
{
  echo "Set up traffic control on an interface."
  echo ""
  echo "Usage: $0 -i IFACE [ -t LINKTYPE ] [ -s LINKSPEED ]"
  echo ""
  echo " -i IFACE       interface name"
  echo ' -t LINKTYPE    "inward" (lan-facing) or "outward" (internet-facing)'
  echo " -s LINKSPEED   maximum egress speed of link, in kbit/s"
  echo " -h             usage"
  echo ""
  echo "default link type is $default_linktype, default link speed is $default_linkspeed."
}

handle_args()
{
  while getopts "i:t:s:h" c
  do
    case $c in
      i) iface=$OPTARG ;;
      t) linktype=$OPTARG ;;
      s) linkspeed=$OPTARG ;;
      h) usage ; exit 1 ;;
      *) echo "unknown option: $OPTARG" ; usage ; exit 1 ;;
    esac
  done

  # set defaults
  [ -z "$iface" ] && usage && exit 1
  [ -z "$linkspeed" ] && linkspeed=$default_linkspeed
  [ -z "$linktype" ] && linktype=$default_linktype
}

set_tc_params()
{
  if [ "$linktype" = "inward" ]; then
    # for the inward facing interface, we can only shape by source port
    porttype=sport
  elif [ "$linktype" = "outward" ]; then
    # for the outward facing interface, we can only shape by destination port
    porttype=dport
  else
    echo "invalid linktype: $linktype"
    usage
    exit 1
  fi

  # ceiling speed is 75% of capacity, to avoid waxy buildup
  ceilspeed=`expr $linkspeed \* 3 / 4`

  # speeds for the various priority classes of traffic
  speed0=`expr $ceilspeed \* 2 / 8`
  speed1=`expr $ceilspeed \* 3 / 8`
  speed2=`expr $ceilspeed \* 3 / 8` 
}

handle_args $@
set_tc_params

# shorten typical tc invocations
tc="/sbin/tc"
tcqdisc="$tc qdisc add dev $iface"
tcclass="$tc class add dev $iface"
u32="$tc filter add dev $iface protocol ip parent 1:0 prio 1 u32"
fwfilter="$tc filter add dev $iface parent 1:0 protocol ip"

# remove existing traffic control structure
$tc qdisc del dev $iface root

# root class. "default 15" means unclassified packets get placed
# in the 1:15 bucket, the slowest one.
$tcqdisc root handle 1: htb default 12

# htb root, htb buckets attach to this. it gets all available bandwidth.
$tcclass parent 1: classid 1:1 htb rate ${ceilspeed}kbit ceil ${ceilspeed}kbit

# htb buckets, in descending order of priority. highly interactive
# traffic consumes fixed bandwidth, while bulk traffic is allowed to
# borrow if there's more available.
$tcclass parent 1:1 classid 1:10 htb rate ${speed0}kbit ceil ${speed0}kbit prio 0
$tcclass parent 1:1 classid 1:11 htb rate ${speed1}kbit ceil ${ceilspeed}kbit prio 1
$tcclass parent 1:1 classid 1:12 htb rate ${speed2}kbit ceil ${ceilspeed}kbit prio 2

# beneath the bulk-traffic buckets, create sfqs for fairness, since they
# are likely to be full.
$tcqdisc parent 1:11 handle 110: sfq perturb 10
$tcqdisc parent 1:12 handle 120: sfq perturb 10

# now that we've established the queue structures, we need to classify
# packets into the queues.

# high priority traffic

# all icmp
$u32 match ip protocol 1 0xff flowid 1:10
# dns
$u32 match ip protocol 17 0xff match ip $porttype 53 0xffff flowid 1:10
# dhcp
$u32 match ip protocol 17 0xff match ip $porttype 67 0xffff flowid 1:10
# ssh
$u32 match ip protocol 6 0xff match ip $porttype 22 0xffff flowid 1:10
# telnet 
$u32 match ip protocol 6 0xff match ip $porttype 23 0xffff flowid 1:10
# irc
$u32 match ip protocol 6 0xff match ip $porttype 6667 0xffff flowid 1:10
# ntp 
$u32 match ip protocol 6 0xff match ip $porttype 123 0xffff flowid 1:10

# bulk traffic 1

# www
$u32 match ip protocol 6 0xff match ip $porttype 80 0xffff flowid 1:11
# ssl
$u32 match ip protocol 6 0xff match ip $porttype 443 0xffff flowid 1:11
# ftp
$u32 match ip protocol 6 0xff match ip $porttype 21 0xffff flowid 1:11

# everything else by default goes to the crap bucket (bulk traffic 2)

