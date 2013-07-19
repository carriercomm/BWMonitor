#!/usr/bin/env perl
# Licence     : GPL
# Author      : Odd Eivind Ebbesen <odd@oddware.net>
# Date        : 2013-07-19 18:34:20
#
# Description :
#


use v5.10;
use strict;
use warnings;

use Test::More;
use Carp;

use BWMonitor::Cmd;
use BWMonitor::Rnd;
use BWMonitor::Logger;

BEGIN {
   use_ok('BWMonitor::Client');
}
require_ok('BWMonitor::Client');

#my $host = '192.168.13.59';
my $host = '127.0.0.1';
my $port = BWMonitor::Cmd::PORT;

my $_c = new_ok('BWMonitor::Client' => [ host => $host ]);
ok(!$_c->connected, "not connected");
ok($_c->connect, "establish connection to host \"$host\" port $port ...");
ok($_c->connected, "is connected");
like($_c->getline, qr/Welcome/, "server greeting");

my $loops = 2;
for (1 .. $loops) {
   my $speed = $_c->download;
   printf("Downloaded %d bytes at %.2f Mbps\n", BWMonitor::Cmd::S_DATA, $speed);
   #printf("Sleeping a couple of seconds to let server fill up buffers...\n");
   sleep(2);
}

ok($_c->disconnect, "tearing down connection");
ok(!$_c->connected, "not connected");


done_testing(9);
