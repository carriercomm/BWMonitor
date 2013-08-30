# Licence     : GPL
# Author      : Odd Eivind Ebbesen <odd@oddware.net>
# Date        : 2013-07-18 17:11:38
#
# Description :
#   Common client methods
#

package BWMonitor::Client;

use v5.10;
use strict;
use warnings;

use Carp;
use IO::Socket::INET;
use BWMonitor::Cmd;
use BWMonitor::Logger;
use BWMonitor::Rnd;

our $VERSION = $BWMonitor::Cmd::VERSION;

### OO subs

sub new {
   my $class = shift;
   my %args  = @_;
   my %cfg   = (
      host    => 'localhost',
      port    => BWMonitor::Cmd::PORT,
      proto   => BWMonitor::Cmd::PROTO,
      timeout => BWMonitor::Cmd::TIMEOUT,
      logger  => BWMonitor::Logger->new,
      cmd     => BWMonitor::Cmd->new,
      sock    => undef,
   );
   # merge args with cfg
   @cfg{ keys(%args) } = values(%args);

   return bless(\%cfg, $class);
}

sub _cmd {
   return shift->{cmd};
}

sub _l {
   return shift->{logger};
}

sub sock {
   return shift->{sock};
}

sub connected {
   my $self = shift;
   return $self->sock && $self->sock->connected() ? $self->sock : undef;
}

sub connect {
   my $self = shift;
   unless ($self->connected) {
      $self->{sock} = IO::Socket::INET->new(
         PeerAddr => $self->{host},
         PeerPort => $self->{port},
         Proto    => $self->{proto},
         Timeout  => $self->{timeout},
      ) or carp($!);
   }
   return $self->sock;
}

sub disconnect {
   my $self = shift;
   if ($self->connected) {
      $self->send($self->_cmd->Q_CLOSE);
      close($self->{sock});
      $self->{sock} = undef;
   }
   return $self;
}

sub getline {
   my $self = shift;
   return unless ($self->connected);
   my $sock = $self->sock;
   chomp(my $ret = <$sock>);
   return $ret;
}

sub send {
   my $self = shift;
   my $sock = $self->connected;
   return unless ($sock);
   if (scalar(@_) > 1) {
      printf($sock shift(@_), @_);
   }
   elsif (scalar(@_) == 1) {
      print($sock shift(@_));
   }
   print($sock $self->_cmd->NL);    # flush FH
   return $self;
}

sub transfer {
   my $self      = shift;
   my $direction = shift;           # Q_DL or Q_UL
   my $cref      = shift;
   my $size_data = shift;
   my $size_buf  = shift;
   my $sock      = $self->sock;
   my $cmd       = $self->_cmd;

   croak("Socket not defined") unless ($sock);
   croak("not a subref") unless ($cref && ref($cref) && ref($cref) eq 'CODE');

   my $ret = $self->send($cmd->q('q', 'set_sizes', $size_data, $size_buf))->getline;
   croak("Expected: " . $cmd->A_ACK . ", got: $ret") unless ($ret eq $cmd->A_ACK);

   $self->send($direction);    # tells server up- or download

   my $t_start   = $self->_l->t_start;
   my $bytes     = $cref->($sock);  # callers code ref should read or write from the socket
   my $t_elapsed = $self->_l->t_stop($t_start);

   # Can use the same function to log back, as when we send($direction), the state is stored
   # in the server (pr client connection) until next call.
   $self->send($cmd->q('q', 'log', $bytes, $t_elapsed, $sock->sockhost, $self->_l->log_time));

   return $self->_l->to_mbit($bytes, $t_elapsed);
}

sub download {
   my $self      = shift;
   my $size_data = shift || $self->_cmd->S_DATA;
   my $size_buf  = shift || $self->_cmd->S_BUF;
   return $self->transfer(
      $self->_cmd->Q_DL,
      sub {
         my $sock = shift;
         my $buf  = '';
         my $read = 0;
         while ($read < $size_data) {
            $read += read($sock, $buf, $size_buf);
         }
         return $read;
      },
      $size_data,
      $size_buf
   );
}

sub upload {
   # BWMonitor::Server will fill up RND buffers at startup, but this module
   # does not, as it very well might be used just for measuring a download.
   # Make sure to initialize and fill up BWMonitor::Rnd buffers from the 
   # calling script if using this subroutine!
   my $self      = shift;
   my $size_data = shift || $self->_cmd->S_DATA;
   my $size_buf  = shift || $self->_cmd->S_BUF;

   # a little failsafe..
   croak("You need to call BWMonitor::Rnd::init before calling BWMonitor::Client::upload() !")
     unless (BWMonitor::Rnd::size() > 0);


   return $self->transfer(
      $self->_cmd->Q_UL,
      sub {
         my $sock    = shift;
         my $written = 0;
         while ($written < $size_data) {
            my $buf = BWMonitor::Rnd::get;    # remember to fill up RND buffer some other place
            $written += length($buf) if (print($sock $buf));
         }
         return $written;
      },
      $size_data,
      $size_buf
   );
}

1;
__END__

