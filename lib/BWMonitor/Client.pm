# Licence: GPL
# Author: Odd Eivind Ebbesen <odd@oddware.net>
# Date: 2013-02-27 15:39:43

package BWMonitor::Client;

use strict;
use warnings;

use IO::Socket::INET;

use BWMonitor::ProtocolCommand;
use BWMonitor::Logger;
use BWMonitor::Producer;
use BWMonitor::Consumer;

sub new {
   my $class = shift;
   my $self  = {
      remote_host => shift,
      remote_port => shift,
      sample_size => shift || BWMonitor::ProtocolCommand::SAMPLE_SIZE,
      buf_size    => shift || BWMonitor::ProtocolCommand::BUF_SIZE,
   };
}

sub download {
   my $self = shift;
}

sub upload {
   my $self = shift;
}

1;
__END__
