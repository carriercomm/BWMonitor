#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use IO::Socket::INET;
use BWMonitor::ProtocolCommand;
use BWMonitor::Producer;

BEGIN {
   use_ok('BWMonitor::Producer');
}
require_ok('BWMonitor::Producer');

done_testing();

