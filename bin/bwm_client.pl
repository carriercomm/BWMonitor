#!/usr/bin/env perl
# Licence     : GPL
# Author      : Odd Eivind Ebbesen <odd@oddware.net>
# Date        : 2013-07-18 19:48:20
#
# Description :
#   Argument parsing frontend script for initiating an instance 
#   of BWMonitor::Client and run requested tests against a BWMonitor::Server.
#

use v5.10;
use strict;
use warnings;

use Getopt::Long;

use lib '../lib';
use BWMonitor::Cmd;
use BWMonitor::Client;
use BWMonitor::Logger;

my $_abort = 0;
my @_results;
my $_opts = {
   host      => 'localhost',
   port      => BWMonitor::Cmd::PORT,
   size_data => BWMonitor::Cmd::S_DATA,    # in bytes
   size_buf  => BWMonitor::Cmd::S_BUF,     # in bytes
   loops     => 1,
   interval  => 0,
};

GetOptions(
   'host=s'      => \$_opts->{host},
   'port=i'      => \$_opts->{port},
   'data_size=i' => \$_opts->{size_data},
   'buf_size=i'  => \$_opts->{size_buf},
   'infinite'    => \$_opts->{infinite},
   'loops=i'     => \$_opts->{loops},
   'interval=i'  => \$_opts->{interval},
   #'verbose'     => \$_opts->{verbose},
   'quiet'       => \$_opts->{quiet},
   'help|?'      => sub { print("Help...\n"); }
) or die($!);

my $log = sub {
   my $fmt = shift;
   if (!$_opts->{quiet}) {
      printf($fmt, @_);
   }
};

local $SIG{INT} = sub {
   $_abort = 1;
   $SIG{INT} = 'IGNORE';
};

my $_c = BWMonitor::Client->new(host => $_opts->{host}, port => $_opts->{port});
$_c->connect or die($!);


$log->(
   "\n" .
   "Server   : %s \n" .
   "Total    : %d bytes\n" .
   "Interval : %d seconds\n" .
   "\n",
   $_opts->{host}, $_opts->{size_data}, $_opts->{interval}
);

$log->("\n[Server Banner]\n%s\n\n", $_c->getline);
$log->("[Results]\n");

my $run_test = sub {
   my $ret = $_c->download($_opts->{size_data}, $_opts->{size_buf});
   push(@_results, $ret);
   $log->(
      "%s : %.2f Mbit/s <= %s\n",
      BWMonitor::Logger::log_time, $ret, $_opts->{host}
   );
   sleep($_opts->{interval});
};

if ($_opts->{infinite}) {
   $run_test->() while (!$_abort);
}
else {
   for (1 .. $_opts->{loops}) {
      last if ($_abort);
      $run_test->();
   }
}

$_c->disconnect;

my $avg;
my $num_results = scalar(@_results);

$avg += $_ foreach (@_results);
$avg = $avg / $num_results;

$log->("\n");
$log->("Date          : %s\n", BWMonitor::Logger::log_time);
$log->("Tests         : %d\n", $num_results);
$log->("Average speed : %.2f Mbit/s\n", $avg);


__END__
