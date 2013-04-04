# Licence: GPL
# Author: Odd Eivind Ebbesen <odd@oddware.net>
# Date: 2013-03-13 19:02:07

package BWMonitor::Server;

use base qw(Net::Server::Multiplex);

use strict;
use warnings;

#use IO::File;
#use IO::Socket::INET;
#use BWMonitor::ProtocolCommand;
#use BWMonitor::Logger;
#use BWMonitor::Producer;
#use BWMonitor::Consumer;

sub new {
   my $class = shift;
   my %args  = @_;
   my %cfg = (
      pcmd      => undef,    # BWMonitor::ProtocolCommand
      logger    => undef,    # BWMonitor::Logger
      producer  => undef,    # BWMonitor::Producer
      consumer  => undef,    # BWMonitor::Consumer
   );
   # merge args with cfg
   @cfg{ keys(%args) } = values(%args);

   return bless({ bwm => \%cfg }, $class);
}

#--- Overridden methods ---

sub mux_connection {
   my $self = shift;
   my $mux  = shift;
   my $fh   = shift;
}

sub mux_input {
   my $self   = shift;
   my $mux    = shift;
   my $fh     = shift;
   my $in_ref = shift;    # scalar ref to input

   while ($$in_ref =~ s/^(.*?)\r?\n//) {
      my $client_input = $1;
   }
}

#---


1;
__END__

