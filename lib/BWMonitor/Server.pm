# Licence: GPL
# Author: Odd Eivind Ebbesen <odd@oddware.net>
# Date: 2013-03-13 19:02:07

package BWMonitor::Server;

use base qw(Net::Server::Fork);

use strict;
use warnings;

use IO::File;
use IO::Socket::INET;
use BWMonitor::ProtocolCommand;
use BWMonitor::Logger;
use BWMonitor::Producer;
use BWMonitor::Consumer;

use Data::Dumper;

sub new {
   my $class = shift;
   my %args  = @_;
   my %cfg = (
      pcmd     => undef,    # BWMonitor::ProtocolCommand
      logger   => undef,    # BWMonitor::Logger
      udp_port => undef,
   );
   # merge args with cfg
   @cfg{ keys(%args) } = values(%args);

   return bless({ bwm => \%cfg }, $class);
}

#--- Overridden methods ---
sub log_time {
   my ($sec, $min, $hour, $day, $mon, $year) = localtime;
   return sprintf "%04d-%02d-%02d_%02d:%02d:%02d", $year + 1900, $mon + 1, $day, $hour, $min, $sec;
}

sub process_request {
   my $self    = shift;
   my $timeout = 30;
   my $pcmd    = \$self->{bwm}{pcmd};    # shortcut, as this obj is often referred

   printf(qq(Welcome to %s (%s)%s), ref($self), $$, $$pcmd->NL);

   my $prev_alarm = alarm($timeout);
   eval {
      local $SIG{ALRM} = sub { die($$pcmd->TIMEOUT_MSG); };

      while (<STDIN>) {
         s/^(.*?)\r?\n$//;
         next unless ($1);
         my $input = $1;
         printf("You said: $input%s", $$pcmd->NL);
       SWITCH: {
            if ($input =~ $$pcmd->Q_QUIT) {
               $self->server_close;
               last SWITCH;
            }
            if ($input =~ $$pcmd->Q_CLOSE) {
               $self->close_client_stdout;
               last SWITCH;
            }
            if ($input =~ $$pcmd->Q_GET) {
               my $data_size = $1;
               my $buf_size  = $2;
               my $p         = BWMonitor::Producer->new(
                  sock_fh => IO::Socket::INET->new(
                     LocalPort => $self->{bwm}{udp_port} // $$pcmd->DATA_PORT,
                     Proto     => 'udp',
                     Timeout   => $$pcmd->TIMEOUT,
                     Type      => SOCK_DGRAM,
                  ),
                  urnd_fh => IO::File->new('/dev/urandom', O_RDONLY),
                  logger  => $self->{bwm}{logger},
                  pcmd    => $$pcmd
               );
               printf("%s%s", $$pcmd->_sub('get', 'a', $self->{bwm}{udp_port}));
               $p->write_rand($data_size, $buf_size);
               last SWITCH;
            }
            if ($input =~ $$pcmd->R_GET) {
               my $bytes   = $1;
               my $seconds = $2;

               $self->log(
                  1,
                  sprintf(
                     "%s %d bytes in %.2f seconds (%.2f Mbit) to peer %s:%d",
                     log_time,
                     $bytes, $seconds, (($bytes * 8) / $seconds) / 1000 / 1000,
                     $self->get_property('peeraddr'),
                     $self->get_property('peerport')
                  )
               );
            }
            # for debugging only, to be removed
            if ($input =~ /^_dump/) {
               printf("%s%s", Dumper($self), $$pcmd->NL);
               $self->get_client_info;
               last SWITCH;
            }
         }
         alarm($timeout);
      }
      alarm($prev_alarm);
   };
   alarm(0);
   if ($@ eq $$pcmd->TIMEOUT_MSG) {
      printf("%s%s", $$pcmd->TIMEOUT_MSG, $$pcmd->NL);
   }
}


#---


1;
__END__

