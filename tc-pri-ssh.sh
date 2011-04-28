#!/bin/bash

set -v

tc="/sbin/tc"
tcqdisc="$tc qdisc add dev ath0"
tcclass="$tc class add dev ath0"
u32="$tc filter add dev ath0 protocol ip parent 1:0 prio 1 u32"

$tc qdisc del dev ath0 root

$tcqdisc root handle 1: prio

$tcqdisc parent 1:1 handle 10: sfq
$tcqdisc parent 1:2 handle 20: sfq
$tcqdisc parent 1:3 handle 30: sfq

