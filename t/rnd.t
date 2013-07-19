#!/usr/bin/env perl

use v5.10;
use strict;
use warnings;

use Test::More tests => 2;
use Benchmark qw(:all);

use BWMonitor::Rnd;

BEGIN {
   use_ok('BWMonitor::Rnd');
}

require_ok('BWMonitor::Rnd');

my $init_runs = 0;
timethis(
   10,
   sub {
      BWMonitor::Rnd::init(sub { ++$init_runs; });
   }
);
print("BWMonitor::Rnd::init ran $init_runs loops\n");

#my $rotate_runs = 0;
#timethis(1000, sub { BWMonitor::Rnd::rotate; ++$rotate_runs; });
#print("BWMonitor::Rnd::rotate ran $rotate_runs times\n");

print("Waiting for ENTER: ");
<STDIN>;

done_testing;
