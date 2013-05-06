# Licence: GPL
# Author: Odd Eivind Ebbesen <odd@oddware.net>
# Date: 2013-04-22 11:07:26

package BWMonitor::ResultLogger;

use strict;
use warnings;
use feature ':5.10';

use Carp;
use IO::File;
use Data::Dumper;
use BWMonitor::ProtocolCommand;

our $VERSION = '2013-04-26';

sub new {
   my $class = shift;
   my %args  = @_;
   my %cfg   = (
      log_file => '/tmp/bwmonitor_results.log',
      log_fh   => undef,
   );

   @cfg{ keys(%args) } = values(%args);

   $cfg{log_fh} = IO::File->new($cfg{log_file}, O_CREAT | O_WRONLY | O_APPEND)
     or croak("Unable to open logfile - $!")
     unless ($cfg{log_fh});

   return bless(\%cfg, $class);
}

sub _fh {
   my $self = shift;
   return $self->{log_fh};
}

sub log {
   my $self = shift;
   my $msg  = shift;
   chomp($msg);
   return unless ($msg);
   if (@_) {
      $msg = sprintf($msg, @_);
   }
   print({ $self->{log_fh} } $msg, BWMonitor::ProtocolCommand::NL);
   return $self;
}

sub DESTROY {
   my $self = shift;
   close($self->_fh) or carp("Unable to close logfile - $!");
}

1;
__END__

