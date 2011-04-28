# wifishape - traffic shaping for an linux open wifi ap #

Up until 2006 I ran an open wifi network with [pebble linux](http://www.nycwireless.net/supernode/pebble-linux/). Here are some scripts that were used to set up traffic prioritization ("make ssh lower latency than http") and bandwidth sharing ("more for me than for the freeloading neighbors").

The [Linux Advanced Routing & Traffic Control HOWTO](http://lartc.org/howto/) was the primary source of inspiration. The most important concept in traffic shaping is this: [you can only control what and when you send, not what and when you receive](http://lartc.org/howto/lartc.qdisc.html#LARTC.QDISC.EXPLAIN). This means that a callous client who doesn't care about getting responses (typically using some UDP protocol like bittorrent) can flood your network just by having access to it. For other protocols, including anything TCP-based, the client will wait for ACKs or some other kind of response, and this is your opportunity to shape traffic by buffering packets for longer or shorter lengths of time.

## Known issues ##

When these scripts were developed, the [SFQ (Stochastic Fairness Queue)](http://linux.die.net/man/8/tc-sfq) couldn't distribute bandwidth on the basis of the NAT IPs, but instead hashed all packets on `source_addr + dest_addr + source_port`, and then bucketed by hash. (This may still be the case, or maybe a viable alternative exists now.) For TCP, the upshot is that bandwidth will be fairly distributed across *connections*. This is bad: a client can simply open more TCP connections to get more bandwidth. Ideally, bandwidth would be distributed on the basis IPs on the local network, but this would require knowledge of what IPs are on the local network, and what IPs are "remote".

