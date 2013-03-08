# Licence: GPL
# Author: Odd Eivind Ebbesen <odd@oddware.net>
# Date: 2013-02-27 10:47:47

package BWMonitor::Consumer;

use strict;
use warnings;
#use IO::Socket::INET;
#use Time::HiRes;

#use BWMonitor::ProtocolCommand;
#use BWMonitor::Logger;

sub new {
   my $class = shift;
   my $self  = {
      sock_fh => shift,    # IO::Socket::INET
      logger  => shift,    # BWMonitor::Logger
      pcmd    => shift,    # BWMonitor::ProtcolCommand
   };
   return unless (defined($self->{sock_fh}));
   binmode($self->{sock_fh});    # will be reading binary
   return bless($self, $class);
}

sub sock {
   return shift()->{sock_fh};
}

sub send {
   return shift()->sock->send(@_);
}

sub recv {
   my $self = shift;
   my $buf_size = shift || $self->{pcmd}->BUF_SIZE;
   my $buf;
   $self->sock->recv($buf, $buf_size);
   return 0 unless ($buf);
   return wantarray ? (length($buf), $buf) : length($buf);
}

# ...?
sub handshake {
   my $self = shift;
   $self->send($self->{pcmd}->HANDSHAKE);
   my ($l, $b) = $self->recv(8);    # random small buffer size
   return ($b == ($self->{pcmd}->HANDSHAKE + $self->{pcmd}->MAGIC));
}

sub read_rand {
   my $self     = shift;
   my $bytes    = shift || $self->{pcmd}->SAMPLE_SIZE;
   my $buf_size = shift || $self->{pcmd}->BUF_SIZE;
   my ($read, $ret) = (0, 0);

   my $t_start = $self->{logger}->t_start;
   while ($read < $bytes) {
      $ret = $self->recv($buf_size);
      last if ($ret == 0);
      $read += $ret;
   }
   my $t_elapsed = $self->{logger}->t_stop($t_start);
   return wantarray ? ($read, $t_elapsed) : $read;
}

#sub DESTROY {
#   my $self = shift;
#   undef($self->{sock_fh});
#}

1;
__END__
