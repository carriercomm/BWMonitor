# Licence     : GPL
# Author      : Odd Eivind Ebbesen <odd@oddware.net>
# Date        : 2013-07-16 11:16:18
#
# Description :
#   Server for downloading/uploading/logging measurements.
#

package BWMonitor::Server;

use v5.10;
use strict;
use warnings;
use base qw(Net::Server::Fork);

use Carp;
use Data::Dumper;
use BWMonitor::Cmd;
use BWMonitor::Graphite;
use BWMonitor::Logger;
use BWMonitor::Rnd;

our $VERSION = BWMonitor::Cmd::VERSION;

### Non OO subs

sub log_time {
   return BWMonitor::Logger->log_time;
}

### OO subs

sub new {
   my $class = shift;
   my %args  = @_;
   my %cfg = (
      pcmd            => BWMonitor::Cmd->new,
      enable_graphite => undef,
      graphite_host   => BWMonitor::Cmd::GRAPHITE_HOST,
      graphite_port   => BWMonitor::Cmd::GRAPHITE_PORT,
      graphite_proto  => BWMonitor::Cmd::GRAPHITE_PROTO,
   );
   # merge args with cfg
   @cfg{ keys(%args) } = values(%args);

   return bless({ bwm => \%cfg }, $class);
}

sub post_configure_hook {
   my $self = shift;
   $self->log(
      4, 
      "Please wait while filling up %d buffers of %d random bytes each...", 
      BWMonitor::Rnd::CHUNK_NUM, 
      BWMonitor::Rnd::CHUNK_SIZE
   );
   BWMonitor::Rnd::init;
   $self->log(4, "Buffers filled!");
}

sub process_request {
   my $self    = shift;
   my $timeout = 30;
   my $pcmd    = \$self->{bwm}{pcmd};    # shortcut, as this obj is often referred

   my $size_dl  = $$pcmd->S_DATA;        # may be changed by client
   my $size_buf = $$pcmd->S_BUF;         # may be changed by client
   my $g;
   if ($self->{bwm}{enable_graphite}) {
      $g = BWMonitor::Graphite->new(
         graphite_host  => $self->{bwm}{graphite_host},
         graphite_port  => $self->{bwm}{graphite_port},
         graphite_proto => $self->{bwm}{graphite_proto}
      );
      $g->connect and $self->log(4, "Connected to Graphite server!");
   }

   # Maybe I should drop this, but it's so cozy, like the "hello world" websites of the early 00's...
   printf("Welcome to %s (%s)%s", ref($self), $$, $$pcmd->NL);

   my $prev_alarm = alarm($timeout);
   eval {
      local $SIG{ALRM} = sub { croak($$pcmd->TIMEOUT_MSG); };

      while (<STDIN>) {
         s/^(.*?)\r?\n$//;
         next unless ($1);
         my $input = $1;
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
               $self->log(4, "Client sets sizes (in bytes), total: $1 buf: $2");
               $size_dl  = $1;
               $size_buf = $2;
               print($$pcmd->A_ACK . $$pcmd->NL);
               last SWITCH;
            }
            # CMD from client to start DL
            if ($input =~ $$pcmd->Q_DL) {
               $self->log(4, "Client requested download");
               my $total = 0;
               while ($total < $size_dl) {
                  my $buf = BWMonitor::Rnd::get;    # will resort to direct read if buffers depleated
                  print($buf);
                  $total += length($buf);
               }
               
               # Important to do this one after the client is done 
               # downloading, to not slow down measurements
               my $filled_buffers = BWMonitor::Rnd::fillup;
               $self->log(4, "Filled $filled_buffers buffers back up with randomness");

               last SWITCH;
            }
            # CMD from client to log results
            if ($input =~ $$pcmd->Q_LOG) {
               my $bytes    = $1;
               my $seconds  = $2;
               my $peerhost = $3;
               my $msg      = $4;
               my $speed    = BWMonitor::Logger->to_mbit($bytes, $seconds);
               (my $listen_addr = $self->{server}{sockaddr}) =~ s/\./_/g;
               (my $nat_addr    = $self->{server}{peeraddr}) =~ s/\./_/g;
               my $path = sprintf(
                  "%sserver_%s.nat_%s.client_%s.download",
                  BWMonitor::Cmd::GRAPHITE_RES_PREFIX,
                  $listen_addr, $nat_addr, $peerhost
               );

               if ($g) {
                  my (undef, $sent) = $g->send($path, $speed);
                  $self->log(4, "Sent $sent bytes to Graphite server");
               }
               $self->log(4, "$msg: $path $speed");
               last SWITCH;
            }
            #
            # for debugging only, to be removed when stable or something...
            if ($input =~ /_dump/) {
               printf("%s%s", Dumper($self), $$pcmd->NL);
               #$self->get_client_info;
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


sub DESTROY {
   my $self = shift;
   BWMonitor::Rnd::cleanup;
}

1;
__END__

