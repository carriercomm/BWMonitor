# Licence: GPL
# Author: Odd Eivind Ebbesen <odd@oddware.net>
# Date: 2013-02-27 10:47:47

package BWMonitor::Consumer;

use strict;
use warnings;

sub new {
   my $class = shift;
   my %args  = @_;
   my %cfg   = (
#      sock_fh => undef,    # IO::Socket::INET
      logger  => undef,    # BWMonitor::Logger
      pcmd    => undef,    # BWMonitor::ProtcolCommand
   );
   @cfg{ keys(%args) } = values(%args);
#   return unless (defined($cfg{sock_fh}));
#   binmode($cfg{sock_fh});    # will be reading binary
   return bless(\%cfg, $class);
}



1;
__END__
