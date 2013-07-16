#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use IO::Socket::INET;
use BWMonitor::ProtocolCommand;
use BWMonitor::Consumer;
use BWMonitor::Logger;

BEGIN {
   use_ok('BWMonitor::Consumer');
}
require_ok('BWMonitor::Consumer');

my $kidpid;
defined($kidpid = fork()) or die("Can't fork: $!");

if ($kidpid) {    # parent
   # Server
   my $ss = IO::Socket::INET->new(
      Proto     => 'udp',
      LocalAddr => '127.0.0.1',
      LocalPort => BWMonitor::ProtocolCommand::DATA_PORT,
      Timeout   => BWMonitor::ProtocolCommand::TIMEOUT,
   ) or die($!);

   binmode($ss);
   my $buf = 0b0000;
   while ($buf != 0b1000) {
      $ss->recv($buf, BWMonitor::ProtocolCommand::BUF_SIZE);
      printf("Received buffer\n");
      $ss->send('0' x BWMonitor::ProtocolCommand::BUF_SIZE);
      printf("Sent buffer\n");
   }
   close($ss);
   done_testing();
}
else {    # child
   # Client
   #sleep(5);
   my $cs = IO::Socket::INET->new(
      Proto    => 'udp',
      PeerAddr => '127.0.0.1',
      PeerPort => BWMonitor::ProtocolCommand::DATA_PORT,
      Timeout  => BWMonitor::ProtocolCommand::TIMEOUT,
   ) or die($!);
   my $c = BWMonitor::Consumer->new(sock_fh => $cs, pcmd => BWMonitor::ProtocolCommand->new, logger => BWMonitor::Logger->new);
   ok(defined($c), 'new() created an instance of Consumer');
   ok($c->isa('BWMonitor::Consumer'), 'Instance is correct class');

   $cs->send(0b0000);
   my ($read, $time) = $c->read_rand();
   #$cs->send(0b1000);
   print("Bytes read: $read, time: $time\n");
   

   undef($c);   # will also close the socket
   done_testing();
}


#my c = BWMonitor::Consumer->new();

