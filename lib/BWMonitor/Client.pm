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

sub download {
   my $self      = shift;
   my $cmd       = $self->_cmd;
   my $sock      = $self->sock;
   my $size_data = shift || $cmd->S_DATA;
   my $size_buf  = shift || $cmd->S_BUF;

   croak("Socket not defined") unless ($sock);

   my $ret = $self->send($cmd->q('q', 'set_sizes', $size_data, $size_buf))->getline;

   my $rlen   = length($ret);
   my $alen   = length($cmd->A_ACK);
   my $errmsg = sprintf("Ret: [%s] (length: %d), Expected: [%s] (length: %d)", $ret, $rlen, $cmd->A_ACK, $alen);

   croak($errmsg) unless ($ret eq $cmd->A_ACK);

   $self->send($cmd->Q_DL);

   my $read    = 0;
   my $buf     = '';
   my $t_start = $self->_l->t_start;
   while ($read < $size_data) {
      $read += read($sock, $buf, $size_buf);
   }
   my $t_elapsed = $self->_l->t_stop($t_start);
   $self->send($cmd->q('q', 'log', $read, $t_elapsed, $sock->sockhost, $self->_l->log_time));

   return $self->_l->to_mbit($read, $t_elapsed);
}

sub upload {
   # TODO:
   # Create the framework to reverse the whole thing
   my $self = shift;
   my $cmd       = $self->_cmd;
   my $sock      = $self->sock;
   my $size_data = shift || $cmd->S_DATA;
   my $size_buf  = shift || $cmd->S_BUF;

   croak("Socket not defined") unless ($sock);
   my $ret = $self->send($cmd->q('q', 'set_sizes', $size_data, $size_buf))->getline;
}

1;
__END__

