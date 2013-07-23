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
use FindBin;

use lib "$FindBin::Bin/../lib";
use BWMonitor::Cmd;
use BWMonitor::Client;
use BWMonitor::Logger;

our $VERSION = $BWMonitor::Cmd::VERSION;

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

sub usage {
   print <<"EOM";

Usage: $0 [ options ]

Options:
   --host       Hostname/IP for the BWMonitor::Server instance to connect to.
                Default: $_opts->{host}  

   --port       TCP port to connect to.
                Default: $_opts->{port}

   --loops      How many tests to run.
                Default: $_opts->{loops}

   --interval   How many seconds to wait between each loop.
                Default: $_opts->{interval}

   --infinite   If set, ignore the value of --loops and run until interrupted.

   --data_size  How many bytes to download in each test.
                Default: $_opts->{size_data} ( See Cmd.pm )

   --buf_size   How big buffers to use, in bytes.
                Default: $_opts->{size_buf} ( See Cmd.pm )

   --quiet      Do not print anything.

   --help       This message.

EOM
   1;
}

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
   'help|?'      => sub { usage; exit 0; }
) or usage and exit 1;

my $log = sub {
   my $fmt = shift;
   if (!$_opts->{quiet}) {
      printf($fmt, @_);
   }
};

# Trap CTRL-C
local $SIG{INT} = sub {
   $_abort = 1;
   $SIG{INT} = 'IGNORE';
};

my $_c = BWMonitor::Client->new(host => $_opts->{host}, port => $_opts->{port});
$_c->connect
  or die(sprintf("Unable to connect to BWMonitor::Server instance at %s:%d\n", $_opts->{host}, $_opts->{port}));


$log->(
   "\n" .
   "Server   : %s \n" .
   "Total    : %d bytes\n" .
   "Interval : %d seconds\n" .
   "\n",
   $_opts->{host}, $_opts->{size_data}, $_opts->{interval}
);

$log->("\n[Server Banner]\n%s\n\n[Results]\n", $_c->getline);

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
