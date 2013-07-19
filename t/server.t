#!/usr/bin/env perl

use v5.10;
use strict;
use warnings;

use Test::More;
use IO::Socket::INET;
#use IO::Handle;
use Carp;

use BWMonitor::Server;
use BWMonitor::Cmd;
use BWMonitor::Logger;
use BWMonitor::Graphite;

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

sleep(7);
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
like($_recv->(), qr/Welcome/, "server greeting");
# Tell server the size of data to DL and buf size
my $_buf_size = $_c->S_BUF;
$_send->(sprintf("_SETS %d %d", $_c->S_DATA, $_buf_size));
# if understood, server sends '_ACK'
$_r = $_recv->();
is($_r, $_c->A_ACK, "Got _ACK from server");

my $_testloops = 1;
for (0 .. $_testloops) {
   # instruct server to begin pumping out random data of given length
   $_send->($_c->Q_DL);
   # read that junk, but check that sizes match
   my $_total = 0;
   my $_start = $_l->t_start;
   while ($_total < $_c->S_DATA) {
      $_total += read($_sock, $_r, $_buf_size);
   }
   my $_elapsed = $_l->t_stop($_start);
   is($_total, $_c->S_DATA, "Read correct number of bytes back");
   $_send->($_c->q('q', 'log', $_total, $_elapsed, $_sock->sockhost, $_l->log_time));
   sleep(5);
}

$_send->($_c->Q_QUIT);

waitpid($kidpid, 0);

done_testing(12 + $_testloops);
