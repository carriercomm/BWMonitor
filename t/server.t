#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use IO::Socket::INET;
use IO::Handle;
use Carp;

use BWMonitor::Server;
use BWMonitor::Cmd;
use BWMonitor::Logger;

BEGIN {
   use_ok('BWMonitor::Cmd');
   use_ok('BWMonitor::Server');
   use_ok('BWMonitor::Logger');
}
require_ok('BWMonitor::Cmd');
require_ok('BWMonitor::Server');
require_ok('BWMonitor::Logger');

my $_tb = Test::More->builder();
$_tb->use_numbers(0);
$_tb->no_ending(1);

my $_c = new_ok('BWMonitor::Cmd');
my $_s = new_ok('BWMonitor::Server');
my $_l = new_ok('BWMonitor::Logger');

defined(my $kidpid = fork()) or die("Can't fork: $!");
if ($kidpid == 0) {
   $_s->run(port => $_c->PORT, log_level => 4);
   exit 0;
}

sleep(1);
my $_sock = IO::Socket::INET->new(
   PeerAddr => 'localhost',
   PeerPort => $_c->PORT,
   Proto    => $_c->PROTO,
   Timeout  => $_c->TIMEOUT_MSG,
) or croak($!);

my $_send = sub { print($_sock @_, $_c->NL); };
my $_recv = sub { chomp(my $ret = <$_sock>); return $ret; };
my $_r; # receive buffer

# get rid of welcome msg
$_recv->(); 
# Tell server the size of data to DL and buf size
$_send->(sprintf("_SETS %d %d", $_c->S_DATA, $_c->S_BUF));
# if understood, server sends '_ACK'
$_r = $_recv->();
is($_r, $_c->A_ACK, "Got _ACK from server");

# instruct server to begin pumping out random data of given length
$_send->($_c->Q_DL);
# read that junk, but check that sizes match
my $_total = 0;
my $_start = $_l->t_start;
while ($_total < $_c->S_DATA) {
   $_total += read($_sock, $_r, $_c->S_BUF);
}
my $_elapsed = $_l->t_stop($_start);
is($_total, $_c->S_DATA, "Read correct number of bytes back");


$_send->($_c->q(undef, 'q', 'log', $_total, $_elapsed, "from testcase"));
$_send->($_c->Q_QUIT);

waitpid($kidpid, 0);

done_testing(11);
