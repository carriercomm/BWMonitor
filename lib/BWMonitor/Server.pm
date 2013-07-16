# Licence: GPL
# Starting over... :(
# Odd, 2013-07-16 11:16:18

package BWMonitor::Server;

use base qw(Net::Server::Fork);

use strict;
use warnings;

use Carp;


sub new {
   my $class = shift;
   my %args  = @_;
   my %cfg = (
      pcmd => BWMonitor::Cmd->new,
   );
   # merge args with cfg
   @cfg{ keys(%args) } = values(%args);

   return bless({ bwm => \%cfg }, $class);
}

sub to_mbit {
   my $self    = shift; # not used
   my $bytes   = shift;
   my $seconds = shift;
   return (($bytes * 8) / $seconds) / 1000 / 1000;
}

sub log_time {
   my ($sec, $min, $hour, $day, $mon, $year) = localtime;
   return sprintf "%04d-%02d-%02d_%02d:%02d:%02d", $year + 1900, $mon + 1, $day, $hour, $min, $sec;
}


sub process_request {
   my $self    = shift;
   my $timeout = 30;
   my $pcmd    = \$self->{bwm}{pcmd};    # shortcut, as this obj is often referred

   my $size_dl  = $$pcmd->S_DATA;        # may be changed by client
   my $size_buf = $$pcmd->S_BUF;         # may be changed by client

   printf("Welcome to %s (%s)%s", ref($self), $$, $$pcmd->NL);

   my $prev_alarm = alarm($timeout);
   eval {
      local $SIG{ALRM} = sub { croak($$pcmd->TIMEOUT_MSG); };

      while (<STDIN>) {
         s/^(.*?)\r?\n$//;
         next unless ($1);
         my $input = $1;
         #printf("You said: $input%s", $$pcmd->NL);
       SWITCH: {
            # CMD from client to close all connections and shut down
            if ($input =~ $$pcmd->Q_QUIT) {
               $self->log(4, "Client tells me to shut down...");
               $self->server_close;
               last SWITCH;
            }
            # CMD from client to close connection
            if ($input =~ $$pcmd->Q_CLOSE) {
               $self->log(4, "Client tells me to close client connection...");
               $self->close_client_stdout;
               last SWITCH;
            }
            # CMD from client to set DL size and buffer size
            if ($input =~ $$pcmd->Q_SET_SIZES) {
               $self->log(4, "Client sets sizes: $1 $2");
               $size_dl  = $1;
               $size_buf = $2;
               print($$pcmd->A_ACK, $$pcmd->NL);
               last SWITCH;
            }
            # CMD from client to start DL
            if ($input =~ $$pcmd->Q_DL) {
               $self->log(4, "Client requested download");
               my $total = 0;
               while ($total < $size_dl) {
                  my $buf = '.' x $size_buf;
                  print($buf);
                  $total += length($buf);
               }
               #print($$pcmd->NL);
               last SWITCH;
            }
            # CMD from client to log results
            if ($input =~ $$pcmd->Q_LOG) {
               my $bytes   = $1;
               my $seconds = $2;
               my $msg     = $3;
               my $speed   = $self->to_mbit($bytes, $seconds);
               $self->log(4, "Client read $bytes bytes in $seconds seconds - speed: $speed Mbps ( $msg )");
               last SWITCH;
            }
            # ...
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


1;
__END__

