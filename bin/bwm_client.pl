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

# Directions (down/up/both)
use constant D_BASE => 0x0001;
use constant D_DOWN => D_BASE << 1;
use constant D_UP   => D_BASE << 2;

our $VERSION = $BWMonitor::Cmd::VERSION;

my $_abort     = 0;
my $_direction = D_BASE;
my $_client;
my @_results_up;
my @_results_down;
my $_opts = {
   host      => '127.0.0.1',
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

   --down       ...

   --up         ...

   --quiet      Do not print anything.

   --help       This message.

EOM
   1;
}

sub _log {
   my $fmt = shift;
   if (!$_opts->{quiet}) {
      printf($fmt, @_);
   }
}


GetOptions(
   'host=s'      => \$_opts->{host},
   'port=i'      => \$_opts->{port},
   'data_size=i' => \$_opts->{size_data},
   'buf_size=i'  => \$_opts->{size_buf},
   'infinite'    => \$_opts->{infinite},
   'loops=i'     => \$_opts->{loops},
   'interval=i'  => \$_opts->{interval},
   'quiet'       => \$_opts->{quiet},
   'down'        => sub { $_direction |= D_DOWN },
   'up'          => sub { $_direction |= D_UP },
   'help|?'      => sub { usage; exit 0; }
) or usage and exit 1;

my $_run_test = sub {
   if ($_direction & D_DOWN) {
      my $ret = $_client->download($_opts->{size_data}, $_opts->{size_buf});
      push(@_results_down, $ret);
      $ret = sprintf("%.2f", $ret);
      _log("%-25s : %9s Mbit/s <== %s\n", BWMonitor::Logger::log_time, $ret, $_opts->{host});
      sleep($_opts->{interval});
   }
   if ($_direction & D_UP) {
      unless (BWMonitor::Rnd::size > 0) {
         #_log("Please wait while filling up RND buffers...\n");
         BWMonitor::Rnd::init();
         #_log("Buffers filled, ready.\n");
      }
      my $ret = $_client->upload($_opts->{size_data}, $_opts->{size_buf});
      push(@_results_up, $ret);
      $ret = sprintf("%.2f", $ret);
      _log("%-25s : %9s Mbit/s ==> %s\n", BWMonitor::Logger::log_time, $ret, $_opts->{host});
      #_log("Refilling RND buffers...\n");
      #BWMonitor::Rnd::fillup;
      sleep($_opts->{interval});
   }
};

my $_summary = sub {
   my $total_up   = 0;
   my $total_down = 0;
   my $num_up     = scalar(@_results_up);
   my $num_down   = scalar(@_results_down);

   if ($num_up > 0) {
      $total_up += $_ foreach (@_results_up);
   }
   if ($num_down > 0) {
      $total_down += $_ foreach (@_results_down);
   }

   _log("[ Summary ]\n\n");

   if ($num_down > 0) {
      _log("Number of download tests  : %d\n",          $num_down);
      _log("Average download speed    : %.2f Mbit/s\n", $total_down / $num_down);
   }
   if ($num_up > 0) {
      _log("Number of upload tests    : %d\n",          $num_up);
      _log("Average upload speed      : %.2f Mbit/s\n", $total_up / $num_up);
   }
};


# Connect and run tests

$_client = BWMonitor::Client->new(
   host => $_opts->{host},
   port => $_opts->{port}
);

$_client->connect or die("Unable to connect to BWMonitor::Server instance at $_opts->{host}:$_opts->{port}\n");

_log("Date                      : %s\n",           BWMonitor::Logger::log_time);
_log("Connected to server       : %s:%d\n",        $_opts->{host}, $_opts->{port});
_log("Server greeting           : %s\n",           $_client->getline);
_log("Numer of tests to run     : %s\n",           $_opts->{infinite} ? "infinite" : $_opts->{loops});
_log("Download/upload data size : %d bytes\n",     $_opts->{size_data});
_log("Pause between test        : %d seconds\n\n", $_opts->{interval});

_log("Press CTRL-C to abort\n\n");
_log("[ Results ]\n\n");

#exit(0);

# Trap CTRL-C
local $SIG{INT} = sub {
   $_abort = 1;
   $SIG{INT} = 'IGNORE';
};

if ($_opts->{infinite}) {
   $_run_test->() while (!$_abort);
}
else {
   for (1 .. $_opts->{loops}) {
      last if ($_abort);
      $_run_test->();
   }
}

$_client->disconnect();

_log("\n");
$_summary->();
_log("\n");

__END__

