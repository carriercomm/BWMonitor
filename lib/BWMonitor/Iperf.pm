# Licence: GPL
# Author: Odd Eivind Ebbesen <odd@oddware.net>
# Date: 2013-02-27 10:46:49

package BWMonitor::Iperf;

use strict;
use warnings;

use POSIX qw(:sys_wait_h);
use Carp;

my %children;

sub new {
   my $class = shift;
   my %args  = @_;
   my %cfg   = (port => undef,);
   @cfg{ keys(%args) } = values(%args);
   return bless(\%cfg, $class);
}

sub kill_child {
   my $pid = shift;
   unless (kill(0 => $pid) || $!{EPERM}) {
      carp("Unable to terminate pid [ $pid ]");
   }
   return kill(INT => $pid);
}

sub start {
   my $self = shift;

   $SIG{CHLD} = sub {
      local ($!, $?);
      my $pid = waitpid(-1, WNOHANG);
      return if ($pid == -1);
      return unless (defined($children{$pid}));
      delete($children{$pid});
      kill_child($pid);
      #$SIG{CHLD} = 'IGNORE';
   };

   #my ($pid, $ipid);
   # Here is a big problem, as I can't get a hold of the real pid,
   # as the value is set after fork, and the outer block don't get the value.
   # Need some sort of IPC here, I think...

   my $pid = fork();
   carp("Unable to fork") unless (defined($pid));
   if ($pid == 0) {    # child
      my $cmd = sprintf("iperf -s -p %d", $self->{port});
      exec($cmd);
      die("exec failed :( - $!");
   }
   else {
      $children{$pid} = 1;
      $self->{iperf_pid} = $pid;
   }
#   unless ($pid = fork) {
#      unless (fork) {
#         my $cmd = sprintf("iperf -s -p %d", $self->{port});
#         exec($cmd);
#         die("exec failed :( - $!");
#      }
#      exit 0;
#   }
#   waitpid($pid, 0);
   return $self->{iperf_pid};
}

sub stop {
   my $self = shift;
   return kill_child($self->{iperf_pid});
}

1;
__END__
