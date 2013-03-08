# Licence: GPL
# Author: Odd Eivind Ebbesen <odd@oddware.net>
# Date: 2013-02-27 10:46:49

package BWMonitor::Producer;

use strict;
use warnings;
#use IO::File;
#use IO::Socket::INET;
#use Data::Dumper;

#use BWMonitor::ProtocolCommand;
#use BWMonitor::Logger;

sub new {
   my $class = shift;
   my $self  = {
      sock_fh => shift,    # IO::Socket::INET
      urnd_fh => shift,    # IO::File->new('/dev/urandom', O_RDONLY)
      logger  => shift,    # BWMonitor::Logger
      pcmd    => shift,    # BWMonitor::ProtocolCommand
   };
   #print(Dumper($self->{sock_fh}));
   return unless (defined($self->{sock_fh}) && defined($self->{urnd_fh}));
   binmode($self->{urnd_fh});    # binary data
   binmode($self->{sock_fh});    # binary data
   return bless($self, $class);
}

sub send {
   return shift()->{sock_fh}->send(@_);
}

sub recv {
   my $self = shift;
   my $buf_size = shift || $self->{pcmd}->BUF_SIZE;
   my $buf;
   $self->{sock_fh}->recv($buf, $buf_size);
   return 0 unless ($buf);
   return wantarray ? (length($buf), $buf) : length($buf);
}

# ...?
sub handshake {
   my $self = shift;
}

sub write_rand {
   my $self     = shift;
   my $bytes    = shift || $self->{pcmd}->SAMPLE_SIZE;
   my $buf_size = shift || $self->{pcmd}->BUF_SIZE;
   my ($read, $written, $buf, $ret) = (0, 0, undef, 0);

   my $t_start = $self->{logger}->t_start;
   #$self->{sock_fh}->recv($buf, $buf_size); # hack, must do one recv to get peer addr
   while ($written <= $bytes) {
      $ret = $self->{urnd_fh}->read($buf, $buf_size);
      if ($ret && $ret > 0) {
         $read = $ret;
         $ret = $self->{sock_fh}->send($buf, $buf_size);
         if ($ret && $ret > 0) {
            $written += $ret;
         }
      }
   }
   my $t_elapsed = $self->{logger}->t_stop($t_start);
   return wantarray ? ($written, $t_elapsed) : $written;
}

#sub DESTROY {
#   my $self = shift;
#   undef($self->{urnd_fh});
#   undef($self->{sock_fh});    # should I leave this to the caller?
#}

1;
__END__
