#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use BWMonitor::ProtocolCommand;
use BWMonitor::Logger;

BEGIN {
   use_ok('BWMonitor::Logger');
}
require_ok('BWMonitor::Logger');

done_testing();


