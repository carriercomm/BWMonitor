#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use IO::Socket::INET;
use BWMonitor::ProtocolCommand;

BEGIN {
   use_ok('BWMonitor::Consumer');
}
require_ok('BWMonitor::Consumer');

my $s = IO::Socket::INET->new(
   Proto     => 'udp',
   LocalAddr => '127.0.0.1',
   LocalPort => BWMonitor::ProtocolCommand::DATA_PORT,
   Timeout   => BWMonitor::ProtocolCommand::TIMEOUT,
) or die($!);

my $data_size = BWMonitor::ProtocolCommand::SAMPLE_SIZE;

my c = BWMonitor::Consumer->new();

done_testing();
