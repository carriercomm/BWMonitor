# Licence: GPL
# Author: Odd Eivind Ebbesen <odd@oddware.net>
# Date: 2013-07-16 15:19:56

package BWMonitor::Logger;

use v5.10;
use strict;
use warnings;

use Time::HiRes;
#use Carp;


sub new {
   state $self;
   return $self //= bless({}, shift);
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

sub to_mbit {
   my $self    = shift;
   my $bytes   = shift;
   my $seconds = shift;
   return (($bytes * 8) / $seconds) / 1000 / 1000;
}

sub log_transfer {
   my $self    = shift;
   my $bytes   = shift;
   my $seconds = shift;
   my $peer    = shift;

   my $mbps = $self->to_mbit($bytes, $seconds);

   # gotta do something else here later
   printf("%s->%s: %d Mbps to %s\n", __PACKAGE__, 'log_transfer()', $mbps, $peer);
}

1;
__END__
