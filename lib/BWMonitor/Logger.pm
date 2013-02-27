# Licence: GPL
# Author: Odd Eivind Ebbesen <odd@oddware.net>
# Date: 2013-02-27 10:48:48

package BWMonitor::Logger;

use strict;
use warnings;

use Time::HiRes;

sub new {
   return bless({[@_]}, shift);
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

1;
__END__
