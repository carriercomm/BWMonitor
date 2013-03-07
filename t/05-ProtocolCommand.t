#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use BWMonitor::ProtocolCommand;

BEGIN {
   use_ok('BWMonitor::ProtocolCommand');
}
require_ok('BWMonitor::ProtocolCommand');

my ($pc, $ret);

$pc = new_ok('BWMonitor::ProtocolCommand');

$ret = $pc->_sub('get', 'q', 8192, 2048);
is($ret, "_GET 8192 2048", $ret);

$ret = $pc->_sub('get', 'a', '127.0.0.1', 10666, 8192, 2048);
is($ret, '_GET_OK 8192 2048 127.0.0.1 10666', $ret);

$ret = $pc->_sub('get', 'r', 8192, 0.010101);
is($ret, '_GET_RESULT 8192 bytes in 0.010101 seconds', $ret);

$ret = $pc->_sub('hello', 'q');
is($ret, '_HELLO ' . $pc->MAGIC, $ret);

done_testing();
