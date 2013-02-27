# Licence: GPL
# Author: Odd Eivind Ebbesen <odd@oddware.net>
# Date: 2013-02-27 10:46:49

package BWMonitor::Producer;

use strict;
use warnings;
use IO::File;
use IO::Socket::INET;

use ProtocolCommand;
use Logger;

sub new {
   my $class = shift;
   my $self  = {
      sock_fh => shift,                                    # must be a socket handle
      urnd_fh => IO::File->new('/dev/urandom', O_RDONLY)
   };
   return unless (defined($self->{sock_fh}) && defined($self->{urnd_fh}));
   $self->{sock_fh}->binmode();
   $self->{urnd_fh}->binmode();
   return bless($self, $class);
}

sub write_rand {
   my $self     = shift;
   my $bytes    = shift;
   my $buf_size = shift || ProtocolCommand::BUF_SIZE;
   my ($read, $written, $buf, $ret);

   my $t_start = Logger->t_start;
   while ($written <= $bytes) {
      $ret = $self->{urnd_fh}->read($buf, $buf_size);
      if ($ret && $ret > 0) {
         $read = $ret;
         $ret = $self->{sock_fh}->send($buf, $buf_size);
         if ($ret && $ret > 0) {
            $written += $ret;
         }
         else {
            last;
         }
      }
      else {
         last;
      }
   }
   my $t_elapsed = Logger->t_stop($t_start);
   return wantarray ? ($written, $t_elapsed) : $written;
}

sub DESTROY {
   my $self = shift;
   undef($self->{urnd_fh});
   undef($self->{sock_fh});    # should I leave this to the caller?
}

1;
__END__
