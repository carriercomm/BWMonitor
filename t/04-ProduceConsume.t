#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use IO::Socket::INET;
use POSIX ();
use BWMonitor::ProtocolCommand;
use BWMonitor::Producer;
use BWMonitor::Consumer;
use BWMonitor::Logger;

my $tb = Test::More->builder();
$tb->use_numbers(0);
$tb->no_ending(1);

BEGIN {
   use_ok('BWMonitor::ProtocolCommand');
   use_ok('BWMonitor::Logger');
   use_ok('BWMonitor::Producer');
   use_ok('BWMonitor::Consumer');
}
require_ok('BWMonitor::ProtocolCommand');
require_ok('BWMonitor::Logger');
require_ok('BWMonitor::Producer');
require_ok('BWMonitor::Consumer');

my $pc     = new_ok('BWMonitor::ProtocolCommand');
my $logger = new_ok('BWMonitor::Logger');
my $host   = '127.0.0.1';
my $port_c = 10443;
my $port_d = 10444;
my $prot_c = 'tcp';
my $prot_d = 'udp';

pass("Before fork");

defined(my $kidpid = fork()) or die("Can't fork: $!");

# child / client
if ($kidpid == 0) {
   my $client_control_socket = IO::Socket::INET->new(
      PeerAddr => $host,
      PeerPort => $port_c,
      Proto    => $prot_c,
      Timeout  => $pc->TIMEOUT
   ) or die($!);
   my $client_data_socket = IO::Socket::INET->new(
      PeerAddr => $host,
      PeerPort => $port_d,
      Proto    => $prot_d,
      Timeout  => $pc->TIMEOUT,
      Type     => SOCK_DGRAM,
   ) or die($!);

   my $cc = new_ok('BWMonitor::Consumer' => [ $client_data_socket, $logger, $pc ]);
   my $data_size = $pc->SAMPLE_SIZE;
   my $buf_size  = $pc->BUF_SIZE;
   my $send      = sub { print($client_control_socket, @_, "\n"); };
   my $recv      = sub { chomp(my $ret = <$client_control_socket>); return $ret; };

   #print("\n[Client]: Servers and clients set up. Press ENTER to continue...\n");
   #<STDIN>;

   # New attempt...
   my $ret;
   $send->($pc->_sub('hello', 'q'));
   $ret = $recv->();
   if ($ret =~ $pc->Q_OK) {
      $send->($pc->_sub('get', 'q', $data_size, $buf_size));
   }

   #my $ret;
   print($client_control_socket $pc->_sub('get', 'q', $data_size, $buf_size), "\n");
#   chomp($ret = <$client_control_socket>);
#   if ($ret =~ BWMonitor::ProtocolCommand::A_GET) {
#      print("Good to go....\n");
#   }

   $cc->init();    # kick the connection alive

   my ($read, $elapsed) = $cc->read_rand($data_size, $buf_size);
   print($client_control_socket $pc->_sub('get', 'r', $read, $elapsed), "\n");
   print($client_control_socket $pc->Q_QUIT, "\n");
   #my $bit_pr_sec = ($read * 8) / $elapsed;
   #my $mbit_pr_sec = $bit_pr_sec / 1000 / 1000;
   #printf("[Client]: Read %d bytes in %f seconds (%.2f Mbps)\n", $read, $elapsed, $mbit_pr_sec);

   is($data_size, $read, "Got the requested data size ($read bytes) back");

   close($client_control_socket);
   close($client_data_socket);
   undef($cc);
   exit;
}
pass("After fork");
# parent / server
my $server_control_socket = IO::Socket::INET->new(
   LocalAddr => $host,
   LocalPort => $port_c,
   Proto     => $prot_c,
   Timeout   => $pc->TIMEOUT,
   Type      => SOCK_STREAM,
   Reuse     => 1,
   Listen    => 1,
) or die($!);
my $server_data_socket = IO::Socket::INET->new(
   LocalAddr => $host,
   LocalPort => $port_d,
   Proto     => $prot_d,
   Timeout   => $pc->TIMEOUT,
   Type      => SOCK_DGRAM,
   Reuse     => 1,
   Listen    => 1,
) or die($!);

my $sp = new_ok('BWMonitor::Producer', [ $server_data_socket, $logger, $pc ]);

ACCEPT:
while (my $c = $server_control_socket->accept) {
   CLIENT_READ:
   while (defined(chomp(my $ret = <$c>))) {
      printf(qq([Server]: Got "%s" from client\n), $ret);
      if ($ret =~ $pc->Q_HELLO) {
         if ($pc->MAGIC == $1) {
            printf($c "%s\n", $pc->A_OK);
         }
         else {
            printf($c "%s\n", $pc->A_NOK);
         }
         next CLIENT_READ;
      }
      elsif ($ret =~ $pc->Q_GET) {
         printf($c "%s\n", $pc->_sub('get', 'a'));
         #$sp->write_rand($1);
      }
      elsif ($ret =~ $pc->R_GET) {
         printf("%d bytes in %f seconds from %s\n", $1, $2, $c->peer);
      }
      elsif ($ret =~ $pc->Q_QUIT) {
         close($c);
         last ACCEPT;
      }
   }
}
waitpid($kidpid, 0);
undef($sp);
close($server_control_socket);

done_testing(15);


