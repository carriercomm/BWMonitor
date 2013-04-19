# Licence: GPL
# Author: Odd Eivind Ebbesen <odd@oddware.net>
# Date: 2013-03-13 19:02:07

package BWMonitor::Server;

use base qw(Net::Server::Fork);

use strict;
use warnings;
use feature ':5.10';

use Carp;
use POSIX qw(setsid);
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
   );
   # merge args with cfg
   @cfg{ keys(%args) } = values(%args);
   return bless({ bwm => \%cfg }, $class);
}

sub iperf_spawn {
   my $port = shift;
   my $pid;
   unless ($pid = fork) {
      unless (fork) {
         close(STDERR);
         close(STDOUT);
         exec('iperf', '-s', '-D', '-p', $port) || croak("Exec failed $!");
      }
      exit(0);
   }
   waitpid($pid, 0);
   return 1;
}

sub iperf_reap {
   return system('killall -9 iperf 2>/dev/null');
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

   iperf_spawn($self->{bwm}{data_port}) or return;
   printf("Welcome to %s (%s)%s", ref($self), $$, $$pcmd->NL);

   my $prev_alarm = alarm($timeout);
   eval {
      local $SIG{ALRM} = sub { iperf_reap; croak($$pcmd->TIMEOUT_MSG); };

    INPUT: {
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
                  $self->log(4, "[ $$ ]: Result (CSV): %s", $csv);
                  last INPUT;
               }
            }
            alarm($timeout);
         }
         alarm($prev_alarm);
      }
   };
   alarm(0);
   if ($@ eq $$pcmd->TIMEOUT_MSG) {
      printf("%s%s", $$pcmd->TIMEOUT_MSG, $$pcmd->NL);
   }
   iperf_reap;
}


#---

1;
__END__

