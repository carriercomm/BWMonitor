# Licence: GPL
# Author: Odd Eivind Ebbesen <odd@oddware.net>
# Date: 2013-03-13 19:02:07

package BWMonitor::Server;

use base qw(Net::Server::Fork);

use strict;
use warnings;

use Carp;
use IO::File;
use IO::Socket::INET;
use BWMonitor::ProtocolCommand;
use BWMonitor::Iperf;

use Data::Dumper;

sub new {
   my $class = shift;
   my %args  = @_;
   my %cfg = (
      pcmd      => undef,    # BWMonitor::ProtocolCommand
      logger    => undef,    # BWMonitor::Logger
      data_port => undef,
      children  => [],
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
      local $SIG{ALRM} = sub { croak($$pcmd->TIMEOUT_MSG); };

      while (<STDIN>) {
         s/^(.*?)\r?\n$//;
         next unless ($1);
         my $input = $1;
         printf("[Server]: You said: $input%s", $$pcmd->NL);
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
               $self->log(4, "Creating Iperf at TCP port $self->{bwm}{data_port}...");
               my $child = BWMonitor::Iperf->new(port => $self->{bwm}{data_port});
               push(@{ $self->{bwm}{children} }, $child);
               my $pid = $child->start;
               $self->log(4, "Started iperf backend with pid: $pid");
               last SWITCH;
            }
            if ($input =~ $$pcmd->R_CSV) {
               my $csv = $1;
               $self->log(4, "Result (CSV): %s", $csv);
               my $child  = shift(@{ $self->{bwm}{children} });
               my $killed = $child->stop;
               $self->log(4, "Killed off $killed iperf child processes");
               last SWITCH;
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

sub DESTROY {
   my $self = shift;
   while(defined(my $ch = shift(@{ $self->{bwm}{children} }))) {
      $ch->stop;
   }
}

#---

1;
__END__

