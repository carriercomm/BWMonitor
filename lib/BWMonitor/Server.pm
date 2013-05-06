# Licence: GPL
# Author: Odd Eivind Ebbesen <odd@oddware.net>
# Date: 2013-03-13 19:02:07

package BWMonitor::Server;

use base qw(Net::Server);

use strict;
use warnings;
use feature ':5.10';

use Carp;
use BWMonitor::ProtocolCommand;
use BWMonitor::ResultLogger;
use BWMonitor::Graphite;
use Data::Dumper;

our $VERSION = '2013-05-03';

sub iperf_spawn {
   my $port = shift || BWMonitor::ProtocolCommand::DATA_PORT;
   my $pid;
   unless ($pid = fork) {
      unless (fork) {
         #close(STDERR);
         #close(STDOUT);
         exec('iperf', '-s', '-D', '-p', $port) || croak("Exec failed $!");
      }
      exit(0);
   }
   waitpid($pid, 0);
   return 1;
}

#sub iperf_spawn {
#   my $port = shift || BWMonitor::ProtocolCommand::DATA_PORT;
#   my $pid = fork;
#   if (defined($pid) && $pid == 0) {
#      close(STDERR);
#      close(STDIN);
#      exec('iperf', '-s', '-p', $port);
#   }
#   elsif ($pid) {
#      waitpid($pid, 0);
#   }
#}

sub iperf_reap {
   return system('killall -9 iperf 2>/dev/null');
}

sub new {
   my $class = shift;
   my %args  = @_;
   my %cfg   = (
      pcmd      => undef,    # BWMonitor::ProtocolCommand
      data_port => undef,
   );
   # merge args with cfg
   @cfg{ keys(%args) } = values(%args);

   #iperf_spawn;

   return bless({ bwm => \%cfg }, $class);
}

#--- Overridden methods ---
sub log_time {
   my ($sec, $min, $hour, $day, $mon, $year) = localtime;
   return sprintf "%04d-%02d-%02d_%02d:%02d:%02d", $year + 1900, $mon + 1, $day, $hour, $min, $sec;
}

sub process_request {
   my $self     = shift;
   my $pcmd     = \$self->{bwm}{pcmd};        # shortcut, as this obj is often referred
   my $timeout  = 30;

   #iperf_spawn($self->{bwm}{data_port}) or return;
   printf("Welcome to %s (%s)%s", ref($self), $$, $$pcmd->NL);

   my $prev_alarm = alarm($timeout);
   eval {
      local $SIG{ALRM} = sub { croak($$pcmd->TIMEOUT_MSG); };

    INPUT: {
         while (<STDIN>) {
            s/\A(.*?)\r?\n\Z//;
            next unless ($1);
            my $input = $1;
            printf("[Server]: You said: $input%s", $$pcmd->NL);
            $self->log(4, "Client sent: %s", $input);
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
                  my $host      = $1;
                  my $timestamp = $2;
                  my $csv       = $3;
                  my ($bw)      = $csv =~ /,([^,]+)\Z/;
                  #$self->log(4, "[ $$ ]: Result: %s %d %s", $host, $timestamp, $csv);
                  BWMonitor::ResultLogger->new->log("%d %s %s", $timestamp, $host, $csv);
                  #BWMonitor::Graphite->new->send($$pcmd->GRAPHITE_RES_PREFIX . $host, $bw, $timestamp)->disconnect;
                  last INPUT;
               }
               # DEBUG
               if ($input =~ /_dump/) {
                  print(Dumper($self));
                  last SWITCH;
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
   #iperf_reap;
}

sub DESTROY {
   #iperf_reap;
}

#---

1;
__END__

