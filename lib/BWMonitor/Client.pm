# Licence: GPL
# Author: Odd Eivind Ebbesen <odd@oddware.net>
# Date: 2013-02-27 15:39:43

package BWMonitor::Client;

use strict;
use warnings;
use feature ':5.10';

use Carp;
use IO::Socket::INET;
use Data::Dumper;
use BWMonitor::ProtocolCommand;
use BWMonitor::Logger;

sub new {
   my $class = shift;
   my %args  = @_;
   my $pcmd  = BWMonitor::ProtocolCommand->new();    # singleton
   my %cfg = (
      logger        => BWMonitor::Logger->new(),    # returns singleton
      pcmd          => $pcmd,
      remote_host   => undef,
      remote_port_c => $pcmd->SERVER_PORT,
      remote_port_d => $pcmd->DATA_PORT,
      sock          => undef,
   );
   @cfg{ keys(%args) } = values(%args);

   croak("Error! You must specify a remote host!") unless (defined($cfg{remote_host}));

   return bless(\%cfg, $class);
}

sub sock {
   my $self = shift;
   return $self->{sock};
}

sub connect {
   my $self = shift;
   return $self->{sock} //= IO::Socket::INET->new(
      PeerHost => $self->{remote_host},
      PeerPort => $self->{remote_port_c},
      Proto    => 'tcp',
      Timeout  => $self->{pcmd}->TIMEOUT,
   ) or croak($!);
}

sub connected {
   my $self = shift;
   my $s    = $self->sock;
   return $s->connected if ($s);
   return undef;
}

sub disconnect {
   my $self = shift;
   if ($self->connected) {
      close($self->{sock}) or carp($!);
   }
   undef($self->{sock});
   return $self;
}

sub send {
   my $self = shift;
   my $s    = $self->sock;
   if ($self->connected) {
      if (@_ > 1) {
         printf($s shift . $self->{pcmd}->NL, @_);
      }
      elsif (@_ == 1) {
         print($s @_, $self->{pcmd}->NL);
      }
      else {
         carp("No data provided to " . __PACKAGE__ . "->send()");
      }
   }
   return $self;
}

sub recv {
   my $self = shift;
   my $s    = $self->sock;
   if ($self->connected) {
      my $buf = <$s>;
      chomp($buf);
      return $buf;
   }
   return undef;
}

sub download {
   my $self = shift;
   my $fh;
   
   $self->send($self->{pcmd}->_sub('get', 'q'));
   printf("%s\n", $self->recv);

   my $child_pid = open($fh, '-|', 'iperf', '-y', 'C', '-c', $self->{remote_host}, '-p', $self->{remote_port_d})
     // croak("Can't fork: $!");

   if ($child_pid) {
      my $res;
#      while (defined($res = <$fh>)) {
#         chomp($res);
#         last;
#      }
      chomp($res = <$fh>);
      close($fh) or carp($!);
      waitpid($child_pid, 0);
      $self->send("%s %s", $self->{pcmd}->Q_CSV, $res);
      return $res;
   }
   else {
      exit;
   }
}
#sub download {
#   my $self = shift;
#   $self->send($self->{pcmd}->_sub('get', 'q'));
#   printf("%s\n", $self->recv);
#   my $result_csv = qx(iperf -y C -c $self->{remote_host} -p $self->{remote_port_d});
#   chomp($result_csv);
#   $self->send("%s %s", $self->{pcmd}->Q_CSV, $result_csv);
#   return $self;
#}

sub upload {
   my $self = shift;
}

1;
__END__
