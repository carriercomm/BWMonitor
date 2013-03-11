#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use IO::Socket::INET;
use POSIX ();
use IO::File;
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

   my $data_size = $pc->SAMPLE_SIZE;
   my $buf_size  = $pc->BUF_SIZE;
   my $send      = sub { print($client_control_socket @_, "\n"); };
   my $recv      = sub { chomp(my $ret = <$client_control_socket>); return $ret; };

   my $ret;
   $send->("tjena");
   $send->($pc->_sub('hello', 'q'));
   $ret = $recv->();
   if ($ret =~ $pc->A_OK) {
      $send->($pc->_sub('get', 'q', $data_size, $buf_size));
      $ret = $recv->();
      printf("[Client]: Server told me: %s\n", $ret);
      if ($ret =~ $pc->A_GET) {
         my $datasize = $1;
         my $bufsize  = $2;
         my $ip       = $3;
         my $port     = $4;
         my $cc       = new_ok(
            'BWMonitor::Consumer' => [
               IO::Socket::INET->new(
                  PeerAddr => $ip,
                  PeerPort => $port,
                  Proto    => $prot_d,
                  Timeout  => $pc->TIMEOUT,
                  Type     => SOCK_DGRAM,
               ),
               $logger, $pc
            ]
         );
         #print("Sending kick...\n");
         #$cc->send($pc->MAGIC);    # must
         #print("Trying to read a bunch of stuff\n");
         my ($read, $elapsed) = $cc->read_rand($datasize, $bufsize);
         is($data_size, $read, "Got the requested data size ($read bytes) back");
         my $bit_pr_sec  = ($read * 8) / $elapsed;
         my $mbit_pr_sec = $bit_pr_sec / 1000 / 1000;
         printf("[Client]: Read %d bytes in %f seconds (%.2f Mbps)\n", $read, $elapsed, $mbit_pr_sec);
         $send->($pc->_sub('get', 'r', $read, $elapsed));
      }
   }

   $send->($pc->Q_QUIT);

#   undef($cc);
#   undef($pc);
#   undef($logger);
#   close($client_control_socket);
#   close($client_data_socket);
   exit 0;
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

ACCEPT:
while (my $c = $server_control_socket->accept) {
   my $ret;
   CLIENTREAD:
   while ($ret = <$c>) {
      chomp($ret);
      next unless ($ret);
      printf(qq([Server]: Got "%s" from client\n), $ret);
      if ($ret =~ $pc->Q_HELLO) {
         #printf("Matched hello at least, with magic: %d\n", $1);
         if ($1 == $pc->MAGIC) {
            #print("Wohooo!\n");
            printf($c "%s\n", $pc->A_OK);
         }
         else {
            printf("D'oh\n");
            printf($c "%s\n", $pc->A_NOK);
         }
         next CLIENTREAD;
      }
      elsif ($ret =~ $pc->Q_GET) {
         my $sp = new_ok(
            'BWMonitor::Producer',
            [  IO::Socket::INET->new(
                  LocalAddr => $host,
                  LocalPort => $port_d,
                  Proto     => $prot_d,
                  Timeout   => $pc->TIMEOUT,
                  Type      => SOCK_DGRAM,
               ),
               IO::File->new('/dev/urandom', O_RDONLY),
               $logger, $pc
            ]
         );
         printf($c "%s\n", $pc->_sub('get', 'a', $c->peerhost, $port_d));
         #$sp->recv(8);
         $sp->write_rand($1, $2);   # bytes, buf_size
      }
      elsif ($ret =~ $pc->R_GET) {
         printf("[Server]: %d bytes in %f seconds from %s\n", $1, $2, $c->peerhost);
      }
      elsif ($ret =~ $pc->Q_QUIT) {
         printf(qq([Server]: Got the kill command, talas...\n));
         close($c);
         close($server_control_socket);
         last ACCEPT;
      }
   }
}
#undef($sp);
#close($server_data_socket);
#close($server_control_socket);
#undef($logger);
#undef($pc);
waitpid($kidpid, 0);

done_testing(15);


