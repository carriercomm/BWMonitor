# Licence     : GPL
# Author      : Odd Eivind Ebbesen <odd@oddware.net>
# Date        : 2013-07-19 18:03:20
#
# Description :
#   Methods to send results to a Graphite server for statistics.
#

package BWMonitor::Graphite;

use strict;
use warnings;

use Carp;
use IO::Socket::INET;
use BWMonitor::Cmd;

our $VERSION = '2013-07-19';

sub new {
   my $class = shift;
   my %args  = @_;
   my %cfg   = (
      graphite_host  => BWMonitor::Cmd::GRAPHITE_HOST,
      graphite_port  => BWMonitor::Cmd::GRAPHITE_PORT,
      graphite_proto => BWMonitor::Cmd::GRAPHITE_PROTO,
   );
   # merge args with cfg
   @cfg{ keys(%args) } = values(%args);
   return bless(\%cfg, $class);
}

sub connect {
   my $self = shift;
   return $self->{sock} if ($self->{sock} && $self->{sock}->connected);

   $self->{sock} = IO::Socket::INET->new(
      PeerHost => $self->{graphite_host},
      PeerPort => $self->{graphite_port},
      Proto    => $self->{proto},
      Timeout  => BWMonitor::Cmd::TIMEOUT,
   ) or croak("Unable to connect to Grahite host @ $self->{graphite_host}:$self->{graphite_port} - $!");

   return $self->{sock};
}

sub send {
   my $self  = shift;
   my $path  = shift;
   my $value = shift;
   my $time  = shift || time;
   my $sock  = $self->connect or croak($!);
   my $msg   = sprintf("%s %s %s%s", $path, $value, $time, BWMonitor::Cmd::NL);
   my $sent  = $sock->send($msg);
   return wantarray ? ($self, $sent) : $self;
}

sub disconnect {
   my $self = shift;
   if ($self->{sock}) {
      $self->{sock}->close;
      $self->{sock} = undef;
   }
   return $self;
}

sub oneshot {
   my $self = shift->new;
   $self->connect or return;
   $self->send(@_);
   $self->disconnect;
}

sub DESTROY {
   shift->disconnect;
}

1;
__END__
