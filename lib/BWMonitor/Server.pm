# Licence: GPL
# Author: Odd Eivind Ebbesen <odd@oddware.net>
# Date: 2013-03-13 19:02:07

package BWMonitor::Server;

use base qw(Net::Server::Fork);

use strict;
use warnings;
use feature ':5.10';

use Carp;
use POSIX ();
use IO::File;
use IO::Socket::INET;
use BWMonitor::ProtocolCommand;
use Data::Dumper;

sub new {
   my $class = shift;
   my %args  = @_;
   my %cfg   = (
      pcmd            => undef,    # BWMonitor::ProtocolCommand
      data_port       => undef,
      iperf_slave_pid => undef,
   );
   # merge args with cfg
   @cfg{ keys(%args) } = values(%args);
   return bless({ bwm => \%cfg }, $class);
}

# Note to self:
# Rewrite this to open a pipe instead, and read its STDERR to capture 
# the PID of iperf, as it will print out something like this at startup:
# $ iperf -s -D -p xxxx
#   Running Iperf Server as a daemon
#   The Iperf daemon process ID : 12850
# $
sub iperf_spawn {
   my $self = shift;
   return if ($self->{bwm}{iperf_slave_pid});
   my $pid = fork;
   croak("Unable to fork off iperf daemon at port $self->{bwm}{data_port} - $!") unless (defined($pid));
   if ($pid == 0) {
      setpgrp;  # please work!
      exec("iperf -s -D -p $self->{bwm}{data_port}") || croak("Exec failed $!");
   }
   $self->{bwm}{iperf_slave_pid} = $pid;
   print("I ($$) think I started an iperf instance with pid $pid but it's probably some other pid...\n");
   return $self->{bwm}{iperf_slave_pid};
}

sub iperf_reap {
   my $self = shift;
   return unless ($self->{bwm}{iperf_slave_pid});
   unless (kill(0 => $self->{bwm}{iperf_slave_pid}) || $!{EPERM}) {
      carp("Unable to terminate pid [ $self->{bwm}{iperf_slave_pid} ]");
      return;
   }
   if (kill(KILL => $self->{bwm}{iperf_slave_pid})) {
      undef($self->{bwm}{iperf_slave_pid});
      wait;
   }
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

   my $iperf_pid = $self->iperf_spawn or croak("Unable to start iperf instance :(");
   printf("Welcome to %s (%s)%s", ref($self), $$, $$pcmd->NL);
   printf("I have a fresh iperf instance with pid %d waiting for your measurements :)\n", $iperf_pid);

   my $prev_alarm = alarm($timeout);
   eval {
      local $SIG{ALRM} = sub { $self->iperf_reap; croak($$pcmd->TIMEOUT_MSG); };

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
            if ($input =~ $$pcmd->R_CSV) {
               my $csv = $1;
               $self->log(4, "Result (CSV): %s", $csv);
               last SWITCH;
            }
#            # for debugging only, to be removed
#            if ($input =~ /^_dump/) {
#               printf("%s%s", Dumper($self), $$pcmd->NL);
#               $self->get_client_info;
#               last SWITCH;
#            }
         }
         alarm($timeout);
      }
      alarm($prev_alarm);
   };
   alarm(0);
   if ($@ eq $$pcmd->TIMEOUT_MSG) {
      printf("%s%s", $$pcmd->TIMEOUT_MSG, $$pcmd->NL);
   }
   $self->iperf_reap;
}

sub DESTROY {
   my $self = shift;
   $self->log(4, "%s instance %d reached end of life. Trying to kill off iperf child pid [ %d ]\n",
      ref($self), $$, $self->{bwm}{iperf_slave_pid});
   $self->iperf_reap;
}

#---

1;
__END__

