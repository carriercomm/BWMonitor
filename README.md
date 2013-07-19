# BWMonitor

## Description:

A client/server application to monitor connection speed between two
endpoints. Intended for measuring the average bandwith over a vpn link
from India to Sweden, but probably usable for more as well.

Implemented as module with scripts using them, performing different
tasks depending on having the role of a client or server.

## Licence:

BWMonitor is released under GPL.

## Technical

The server listens on a TCP socket, running in the background as a
daemon. When a client connects, it forks off a new process to handle that
session, while itself returning to listening for more new clients. The
forked off process for each connection will scan input for defined
commands. According to the command given, it will then set parameters,
start a download measurement, log the results, close or quit, depending
on it's input.

To ensure sufficient efficiency, the server, when it starts up, will
initialize BWMonitor::Rnd, which in turn will fill up its configured size
buffers with random data. It's left up to the consumer of BWMonitor::Rnd
to make sure to refill the random data buffers, or speed will slow down
when they're empty, as the data will then be read for each request,
instead of just being pulled from RAM.

Both commands and random data are pushed through the same TCP
connection. Earlier versions had a TCP channel for commands and a separate
UDP channel for measuring bandwidth. But as the real life usage pattern
for this application is anyways for TCP, the overhead of TCP is not
worth the overhead of the code for an extra UDP channel.

### Platform

[Perl](http://www.perl.org)

## Summary

A bandwidth measurement tool. Client/server model. Alternative to iperf.

## Author

Odd Eivind Ebbesen <odd@oddware.net>, 2013-07-19 19:25:56


