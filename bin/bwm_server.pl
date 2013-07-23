#!/usr/bin/env perl
# Licence     : GPL
# Author      : Odd Eivind Ebbesen <odd@oddware.net>
# Date        : 2013-07-18 19:17:23
#
# Description :
#   Argument parsing frontend script for starting an instance 
#   of BWMonitor::Server.
#

use v5.10;
use strict;
use warnings;

use Getopt::Long;
use FindBin;
use Data::Dumper;

use lib "$FindBin::Bin/../lib";
use BWMonitor::Cmd;
use BWMonitor::Server;

our $VERSION = $BWMonitor::Cmd::VERSION;

my $_opts = {
   port           => BWMonitor::Cmd::PORT,
   graphite_host  => BWMonitor::Cmd::GRAPHITE_HOST,
   graphite_port  => BWMonitor::Cmd::GRAPHITE_PORT,
   graphite_proto => BWMonitor::Cmd::GRAPHITE_PROTO,
};

sub usage {
   print <<"EOM";

Usage: $0 [ options ]

Options: 
   --port               TCP port to listen on.
                        Default: $_opts->{port}

   --graphite           Enable reporting to a Graphite server instance.
                        Default: disabled

   --graphite_host      Hostname/IP where the Graphite server resides.
                        Default: $_opts->{graphite_host}

   --graphite_port      Which port the Graphite server listens on.
                        Default: $_opts->{port}

   --graphite_proto     Protocol for talking to Graphite. TCP or UDP.
                        Default: $_opts->{graphite_proto}

   --help               This message. Pass -v or --verbose _before_ the 
                        --help flag to show some extra stuff.


You can also pass options recognized by Net::Server directly by
terminating the option list for this script with -- and then pass the
options for Net::Server.

E.g.
\$ $0 --port 10443 -- --log_level 4

(--port is actually recognized by both this frontend and Net::Server itself. 
It is just passed on).

EOM

   if ($_opts->{verbose}) {
      print('#' x 72, "\n");
      print while (<DATA>);
      print('#' x 72, "\n");
   }

   1;
}

GetOptions(
   'port=i'             => \$_opts->{port},
   'graphite'           => \$_opts->{graphite},
   'graphite_host|gh=s' => \$_opts->{graphite_host},
   'graphite_port|gp=s' => \$_opts->{graphite_port},
   'graphite_proto=s'   => \$_opts->{graphite_proto},
   'verbose'            => \$_opts->{verbose},
   'help|?'             => sub { usage; exit 0; }
) or usage && exit 1;

BWMonitor::Server->new(
   enable_graphite => $_opts->{graphite},
   graphite_host   => $_opts->{graphite_host},
   graphite_port   => $_opts->{graphite_port},
   graphite_proto  => $_opts->{graphite_proto},
  )->run(
   port => $_opts->{port}, 
   @ARGV
);


__DATA__

Copied from :
http://search.cpan.org/~rhandom/Net-Server-2.007/lib/Net/Server.pod

Parameters for Net::Server that can be given on the command line or 
set in a config file.


Key               Value                    Default
---------------------------------------------------
conf_file         "filename"               undef

log_level         0-4                      2
log_file          (filename|Sys::Syslog
                   |Log::Log4perl)         undef

port              \d+                      20203
host              "host"                   "*"
ipv               (4|6|*)                  *
proto             (tcp|udp|unix)           "tcp"
listen            \d+                      SOMAXCONN

## syslog parameters (if log_file eq Sys::Syslog)
syslog_logsock    (native|unix|inet|udp
                   |tcp|stream|console)    unix (on Sys::Syslog < 0.15)
syslog_ident      "identity"               "net_server"
syslog_logopt     (cons|ndelay|nowait|pid) pid
syslog_facility   \w+                      daemon

reverse_lookups   1                        undef
allow             /regex/                  none
deny              /regex/                  none
cidr_allow        CIDR                     none
cidr_deny         CIDR                     none

## daemonization parameters
pid_file          "filename"               undef
chroot            "directory"              undef
user              (uid|username)           "nobody"
group             (gid|group)              "nobody"
background        1                        undef
setsid            1                        undef

no_close_by_child (1|undef)                undef

## See Net::Server::Proto::(TCP|UDP|UNIX|SSL|SSLeay|etc)
## for more sample parameters.

