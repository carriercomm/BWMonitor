# Licence: GPL
# Author: Odd Eivind Ebbesen <odd@oddware.net>
# Date: 2013-02-27 10:47:47

package BWMonitor::Consumer;

use strict;
use warnings;
use IO::Socket::INET;
#use Time::HiRes;

use BWMonitor::ProtocolCommand;
use BWMonitor::Logger;

sub new {
   my $class = shift;
   my $self = { sock_fh => shift, };    # for reading, eg. client
   return unless (defined($self->{sock_fh}));
   binmode($self->{sock_fh});
   return bless($self, $class);
}

sub read_rand {
   my $self     = shift;
   my $bytes    = shift || BWMonitor::ProtocolCommand::SAMPLE_SIZE;
   my $buf_size = shift || BWMonitor::ProtocolCommand::BUF_SIZE;
   my ($read, $buf, $ret) = (0, undef, 0);

   my $t_start = BWMonitor::Logger->t_start;
   while ($read < $bytes) {
      $self->{sock_fh}->recv($buf, $buf_size);
      $ret = length($buf);
      $read += $ret if ($ret);
      #Time::HiRes::usleep(1000);
   }
   my $t_elapsed = BWMonitor::Logger->t_stop($t_start);
   return wantarray ? ($read, $t_elapsed) : $read;
}

sub send {
   my $self = shift;
   return $self->{sock_fh}->send(@_);
}

sub init {
   my $self = shift;
   return $self->send(0x0);
}

sub DESTROY {
   my $self = shift;
   undef($self->{sock_fh});
}

1;
__END__
