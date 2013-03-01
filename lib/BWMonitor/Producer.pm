# Licence: GPL
# Author: Odd Eivind Ebbesen <odd@oddware.net>
# Date: 2013-02-27 10:46:49

package BWMonitor::Producer;

use strict;
use warnings;
use IO::File;
use IO::Socket::INET;
use Data::Dumper;

use BWMonitor::ProtocolCommand;
use BWMonitor::Logger;

sub new {
   my $class = shift;
   my $self  = {
      sock_fh => shift,                                    # must be a socket handle, for writing, for writing
      urnd_fh => IO::File->new('/dev/urandom', O_RDONLY)
   };
   #print(Dumper($self->{sock_fh}));
   return unless (defined($self->{sock_fh}) && defined($self->{urnd_fh}));
   binmode($self->{urnd_fh});
   binmode($self->{sock_fh});
   return bless($self, $class);
}

sub write_rand {
   my $self     = shift;
   my $bytes    = shift || BWMonitor::ProtocolCommand::SAMPLE_SIZE;
   my $buf_size = shift || BWMonitor::ProtocolCommand::BUF_SIZE;
   my ($read, $written, $buf, $ret) = (0, 0, undef, 0);

   my $t_start = BWMonitor::Logger->t_start;
   $self->{sock_fh}->recv($buf, $buf_size); # hack?
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
   my $t_elapsed = BWMonitor::Logger->t_stop($t_start);
   return wantarray ? ($written, $t_elapsed) : $written;
}

sub DESTROY {
   my $self = shift;
   undef($self->{urnd_fh});
   undef($self->{sock_fh});    # should I leave this to the caller?
}

1;
__END__
