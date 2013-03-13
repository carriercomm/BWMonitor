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

The server listens on a TCP socket, running continously, acting as
a command channel. Clients then connect to this and send predefined
commands with parameters. If the requested operation is reading/writing
a certain amount of data, the server replies with a status and parameters
for where to connect via UDP. The client then opens a new connection via
UDP, kicks off one byte over the wire to the server (just to make the
server aware of the connection, as UDP is stateless), sets a timestamp,
then starts to read until the requested data size is read, and sets
the end timestamp. The data is discarded immediately, as the purpose
on this channel is _only_ to measure the speed. The server, in turn,
just pours out data directly to the UDP socket read from `/dev/urandom`
(or any other open filehandle given - this is just the original thought)
until the specified data size is transferred.  The client may then send
the results of it's test back to the server via the TCP control channel
for logging purposes, and then either disconnect, or request some other
operation (just to not exclude possible future additional features).

### Platform

[Perl](http://www.perl.org)

## Summary

Basically, just a simplified rip-off of the FTP protocol, trimmed down
for a specific need, but hopefully extensible for other purposes.

## Author

Odd Eivind Ebbesen <oddebb@gmail.com>, 2013-03-13 18:31:06


