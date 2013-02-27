# Licence: GPL
# Author: Odd Eivind Ebbesen <odd@oddware.net>
# Date: 2013-02-27 10:47:47

package BWMonitor::Consumer;

use strict;
use warnings;
use IO::Socket::INET;

use BWMonitor::ProtocolCommand;
use BWMonitor::Logger;

sub new {
   my $class = shift;
   my $self = { sock_fh => shift, };
   return unless (defined($self->{sock_fh}));
   $self->{sock_fh}->binmode();
   return bless($self, $class);
}

sub read_rand {
   my $self     = shift;
   my $bytes    = shift || BWMonitor::ProtocolCommand::SAMPLE_SIZE;
   my $buf_size = shift || BWMonitor::ProtocolCommand::BUF_SIZE;
   my ($read, $buf, $ret);

   my $t_start = BWMonitor::Logger->t_start;
   while ($read <= $bytes) {
      $ret = $self->{sock_fh}->recv($buf, $buf_size);
      if ($ret > 0) {
         $read += $ret;
      }
      else {
         last;
      }
   }
   my $t_elapsed = BWMonitor::Logger->t_stop($t_start);
   return wantarray ? ($read, $t_elapsed) : $read;
}

sub DESTROY {
   my $self = shift;
   undef($self->{sock_fh});
}

1;
__END__
