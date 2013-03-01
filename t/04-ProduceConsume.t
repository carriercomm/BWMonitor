#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use IO::Socket::INET;
use BWMonitor::ProtocolCommand;
use BWMonitor::Producer;
use BWMonitor::Consumer;

my $tb = Test::More->builder();
$tb->use_numbers(0);
$tb->no_ending(1);

BEGIN {
   use_ok('BWMonitor::Producer');
   use_ok('BWMonitor::Consumer');
}
require_ok('BWMonitor::Producer');
require_ok('BWMonitor::Consumer');

my $host   = '127.0.0.1';
my $port_c = 10443;
my $port_d = 10444;
my $prot_c = 'tcp';
my $prot_d = 'udp';

pass("Before fork");

defined(my $kidpid = fork()) or die("Can't fork: $!");

if ($kidpid == 0) {    # child
   my $client_control_socket = IO::Socket::INET->new(
      PeerAddr => $host,
      PeerPort => $port_c,
      Proto    => $prot_c,
      Timeout  => BWMonitor::ProtocolCommand::TIMEOUT
   ) or die($!);
   my $client_data_socket = IO::Socket::INET->new(
      PeerAddr => $host,
      PeerPort => $port_d,
      Proto    => $prot_d,
      Timeout  => BWMonitor::ProtocolCommand::TIMEOUT
   ) or die($!);

   my $cc = new_ok('BWMonitor::Consumer' => [$client_data_socket]);

   print($client_control_socket "GET ", BWMonitor::ProtocolCommand::SAMPLE_SIZE, "\n");
   $client_data_socket->send(0x0);  # kick the connection alive

   my ($read, $elapsed) = $cc->read_rand(BWMonitor::ProtocolCommand::SAMPLE_SIZE);
   print($client_control_socket "QUIT\n");
   printf("Read %d bytes in %f seconds (%f)\n", $read, $elapsed, ($read/$elapsed));
   is(BWMonitor::ProtocolCommand::SAMPLE_SIZE, $read, "Got the requested data size back");

   close($client_control_socket);
   undef($cc);
   exit;
}
pass("After fork");
# parent
my $server_control_socket = IO::Socket::INET->new(
   LocalAddr => $host,
   LocalPort => $port_c,
   Proto     => $prot_c,
   Timeout   => BWMonitor::ProtocolCommand::TIMEOUT,
   Type      => SOCK_STREAM,
   Reuse     => 1,
   Listen    => 1,
) or die($!);
my $server_data_socket = IO::Socket::INET->new(
   LocalAddr => $host,
   LocalPort => $port_d,
   Proto     => $prot_d,
   Timeout   => BWMonitor::ProtocolCommand::TIMEOUT
) or die($!);

my $sp = new_ok('BWMonitor::Producer', [$server_data_socket]);

ACCEPT:
while (my $c = $server_control_socket->accept) {
   while (defined(chomp(my $ret = <$c>))) {
      if ($ret =~ /GET (\d+)/) {
         $sp->write_rand($1);
      }
      elsif ($ret =~ /^QUIT/) {
         print("Got QUIT...\n");
         close($c);
         last ACCEPT;
      }
   }
}
waitpid($kidpid, 0);
undef($sp);
close($server_control_socket);

done_testing(9);


