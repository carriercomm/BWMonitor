# Licence: GPL
# Author: Odd Eivind Ebbesen <odd@oddware.net>
# Date: 2013-02-27 10:47:47

package BWMonitor::Consumer;

use strict;
use warnings;
use Carp;
use Data::Dumper;

sub new {
   my $class = shift;
   my %args  = @_;
   my %cfg   = (
      sock_fh => undef,    # IO::Socket::INET
      logger  => undef,    # BWMonitor::Logger
      pcmd    => undef,    # BWMonitor::ProtcolCommand
   );
   @cfg{ keys(%args) } = values(%args);
   unless (defined($cfg{sock_fh})) {
      croak(Dumper($class, \@_));
   }
   binmode($cfg{sock_fh});    # will be reading binary
   return bless(\%cfg, $class);
}

sub _set {
   my $self = shift;
   my $key  = shift;
   if (@_) {
      $self->{$key} = shift;
   }
   return $self;
}

sub sock {
   my $k = 'sock_fh';
   return shift()->_set($k, @_)->{$k};
}

sub logger {
   my $k = 'logger';
   return shift()->_set($k, @_)->{$k};
}

sub pcmd {
   my $k = 'pcmd';
   return shift()->_set($k, @_)->{$k};
}

sub send {
   return shift()->sock->send(@_);
}

sub recv {
   my $self = shift;
   my $buf_size = shift || $self->pcmd->BUF_SIZE;
   my $buf;
   $self->{sock_fh}->recv($buf, $buf_size);
   return 0 unless ($buf);
   #printf("%s->recv() : Read %d bytes...\n", __PACKAGE__, length($buf));
   return wantarray ? (length($buf), $buf) : length($buf);
}

sub read_rand {
   my $self     = shift;
   my $bytes    = shift || $self->pcmd->SAMPLE_SIZE;
   my $buf_size = shift || $self->pcmd->BUF_SIZE;
   my ($read, $ret) = (0, 0);

   # kick the socket alive
   $self->send(1);

   my $t_start = $self->logger->t_start;
   while ($read < $bytes) {
      $ret = $self->recv($buf_size);
      last if ($ret == 0);
      $read += $ret;
      #print("Read: $read\n");
   }
   #print("Done reading\n");
   my $t_elapsed = $self->logger->t_stop($t_start);
   return wantarray ? ($read, $t_elapsed) : $read;
}


1;
__END__
