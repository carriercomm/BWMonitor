# Licence: GPL
# Author: Odd Eivind Ebbesen <odd@oddware.net>
# Date: 2013-02-27 10:48:48

package BWMonitor::Logger;

use strict;
use warnings;

use Time::HiRes;

my $_singleton;

sub new {
   return $_singleton //= bless({}, shift);
}

sub t_start {
   my $self = shift;
   return [Time::HiRes::gettimeofday];
}

sub t_stop {
   my $self  = shift;
   my $start = shift;
   return Time::HiRes::tv_interval($start);
}

sub log_transfer {
   my $self    = shift;
   my $bytes   = shift;
   my $seconds = shift;
   my $peer    = shift;

   my $bps = ($bytes * 8) / $seconds;
   my $mbps = $bps / 1000 / 1000;

   # gotta do something else here later
   printf("%s->%s: %d Mbps to %s\n", __PACKAGE__, 'log_transfer()', $mbps, $peer);
}

1;
__END__
