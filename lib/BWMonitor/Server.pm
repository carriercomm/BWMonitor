# Licence: GPL
# Author: Odd Eivind Ebbesen <odd@oddware.net>
# Date: 2013-03-13 19:02:07

package BWMonitor::Server;

use strict;
use warnings;

use IO::File;
use IO::Socket::INET;
use BWMonitor::ProtocolCommand;
use BWMonitor::Logger;
use BWMonitor::Producer;
use BWMonitor::Consumer;

sub new {
   my $class = shift;
   my %args  = @_;
   my %cfg = (
      pcmd      => undef,    # BWMonitor::ProtocolCommand
      logger    => undef,    # BWMonitor::Logger
      producer  => undef,    # BWMonitor::Producer
      consumer  => undef,    # BWMonitor::Consumer
      sock_ctrl => undef,    # IO::Socket::INET
   );
   # merge args with cfg
   @cfg{ keys(%args) } = values(%args);

   return bless(\%cfg, $class);
}

# Wrapper for new, where all instances are created internally
sub default_new {
   my $class      = shift;
   my $pcmd       = BWMonitor::ProtocolCommand->new;
   my $logger     = BWMonitor::Logger->new;
   my $urnd_fh    = IO::File->new('/dev/urandom', O_RDONLY) or die($!);
   my $sock_tcp_c = IO::Socket::INET->new(
      LocalPort => $pcmd->SERVER_PORT,
      Proto     => 'tcp',
      Timeout   => $pc->TIMEOUT,
      Type      => SOCK_STREAM,
      Reuse     => 1,
      Listen    => SOMAXCONN,
   ) or die($!);
   my $sock_udp_p = IO::Socket::INET->new(
      LocalPort => $pcmd->DATA_PORT,
      Proto     => 'udp',
      Timeout   => $pcmd->TIMEOUT,
      Type      => SOCK_DGRAM
   ) or die($!);
   my $producer = BWMonitor::Producer->new($sock_udp_p, $urnd_fh, $logger, $pc);
   my $self = $class->new(pcmd => $pcmd, logger => $logger, producer => $producer, sock_ctrl => $sock_tcp_c, cleanup => 1);
}

sub run {
}

sub DESTROY {
   # We set the key "cleanup" in default_new() if we need to close sockets etc. ourselves at shutdown.
   # If the instance was created from somewhere else, they should do the cleanup themselves.
   my $self = shift;
   if (exists($self->{cleanup}) && $self->{cleanup}) {
      $self->{producer}->cleanup;   # instance does not clean after itself automatically
      undef($self->{producer}); 
      close($self->{sock_ctrl});
   }
}

1;
__END__

