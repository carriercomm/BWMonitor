# Licence: GPL
# Author: Odd Eivind Ebbesen <odd@oddware.net>
# Date: 2013-04-23 08:54:54

package BWMonitor::Graphite;

use strict;
use warnings;

use Carp;
use IO::Socket::INET;
use BWMonitor::ProtocolCommand;

our $VERSION = '';

sub new {
   my $class = shift;
   my %args  = @_;
   my %cfg = (
      graphite_host => BWMonitor::ProtocolCommand::GRAPHITE_HOST,
      graphite_port => BWMonitor::ProtocolCommand::GRAPHITE_PORT,
      proto         => BWMonitor::ProtocolCommand::GRAPHITE_PROT,
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
      Timeout  => BWMonitor::ProtocolCommand::TIMEOUT,
   ) or croak("Unable to connect to Grahite host @ $self->{graphite_host}:$self->{graphite_port} - $!");

   return $self->{sock};
}

sub send {
   my $self  = shift;
   my $path  = shift;
   my $value = shift;
   my $time  = shift || time;
   my $sock  = $self->connect;
   my $msg   = sprintf("%s %s %s%s", $path, $value, $time, BWMonitor::ProtocolCommand::NL);
   return $sock->send($msg);
}

sub disconnect {
   my $self = shift;
   if ($self->{sock}) {
      $self->{sock}->close;
      $self->{sock} = undef;
   }
   return $self;
}

#sub close {
#   return shift->disconnect;
#}

sub DESTROY {
   shift->disconnect;
}

1;
__END__

