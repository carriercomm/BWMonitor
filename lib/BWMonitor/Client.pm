# Licence: GPL
# Author: Odd Eivind Ebbesen <odd@oddware.net>
# Date: 2013-02-27 15:39:43

package BWMonitor::Client;

use strict;
use warnings;

use Carp;
use IO::Socket::INET;
use Data::Dumper;
use BWMonitor::ProtocolCommand;
use BWMonitor::Logger;
use BWMonitor::Producer;
use BWMonitor::Consumer;

sub new {
   my $class = shift;
   my %args  = @_;
   my $pcmd  = BWMonitor::ProtocolCommand->new();    # singleton
   my %cfg   = (
      logger      => BWMonitor::Logger->new(),       # returns singleton
      pcmd        => $pcmd,
      remote_host => undef,
      remote_port => $pcmd->SERVER_PORT,
      sample_size => $pcmd->SAMPLE_SIZE,
      buf_size    => $pcmd->BUF_SIZE,
      sock        => undef,
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
      PeerPort => $self->{remote_port},
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
   print("Sending request for Dl to server...\n");
   my $status = $self->send($self->{pcmd}->_sub('get', 'q', $self->{data_size}, $self->{buf_size}))->recv;
   #my $status = $self->recv;
   #print("status: ", Dumper($status), $self->{pcmd}->NL);
   if ($status =~ $self->{pcmd}->A_GET) {
      print("Ready to download...\n");
      my $sample_size = $1;
      my $buf_size    = $2;
      my $udp_port    = $3;
      my $consumer    = BWMonitor::Consumer->new(
         sock_fh => IO::Socket::INET->new(
            PeerAddr => $self->{remote_host},
            PeerPort => $udp_port,
            Proto    => 'udp',
            Type     => SOCK_DGRAM,
            Timeout  => $self->{pcmd}->TIMEOUT
         ),
         pcmd   => $self->{pcmd},
         logger => $self->{logger}
      );
      my ($read, $elapsed) = $consumer->read_rand($sample_size, $buf_size);
      $self->send($self->{pcmd}->_sub('get', 'r', $read, $elapsed));    # log result back to server
      return $self->{logger}->to_mbit($read, $elapsed);
   }
   else {
       print("No match:\n\t");
       print($status, "\n");
   }
   # FAIL
   return undef;
}

sub upload {
   my $self = shift;
}

1;
__END__
