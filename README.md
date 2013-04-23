# BWMonitor

## Description:

A client/server application to monitor connection speed between two
endpoints. Intended for measuring the average bandwith over a vpn link
from India to Sweden, but probably usable for more as well.

Implemented as module with scripts using them, performing different
tasks depending on having the role of a client or server.

## Licence:

BWMonitor is released under GPLv2.

## Technical


The server listens on a TCP socket, running continously, acting as a
control/command channel. Clients connect and send predifined commands,
including results of the measurement back to the server. The server will
spawn off an iperf instance in the background for each connection and
kill it off again when the client disconnects, or when the client sends
back results of the measurement. The results are logged on the server,
and passed on to a local Graphite instance for displaying graphs.

The first version of this application was implemented in pure Perl,
but as performance was crap, I changed over to using "iperf" as the
measurement backend. I might go back to pure Perl if I can improve the
performance to be on par with iperf.


### Platform

[Perl](http://www.perl.org)

## Summary

A wrapper around "iperf" for easily logging and passing off data to Graphite.

## Author

Odd Eivind Ebbesen <oddebb@gmail.com>, 2013-03-13 18:31:06


