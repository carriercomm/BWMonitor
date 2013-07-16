#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 3;
use Carp;

use BWMonitor::Server;
use BWMonitor::Cmd;
use BWMonitor::Logger;

BEGIN {
   use_ok('BWMonitor::Cmd');
}
require_ok('BWMonitor::Cmd');

my $_c = new_ok('BWMonitor::Cmd');

my $r1 = $_c->q(undef, 'q', 'set_sizes', 100, 10);
print("R1: $r1 \n");

my $r2 = $_c->q(undef, 'test', 'lvl1', 'lvl2', 'parameters', 'should', 'be', 'preserved');
print("R2: $r2 \n");

done_testing;
