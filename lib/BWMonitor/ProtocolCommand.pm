# Licence: GPL
# Author: Odd Eivind Ebbesen <odd@oddware.net>
# Date: 2013-02-26 23:28:46

package BWMonitor::ProtocolCommand;

use strict;
use warnings;

our $VERSION = '0.0.8';

use constant {
   TIMEOUT       => 5,
   SERVER_PORT   => 10443,
   DATA_PORT     => 10444,
   NL            => "\012\015",
   R_CSV         => qr/_RESULT_CSV\s+(.*)$/,
   Q_CSV         => '_RESULT_CSV',
   Q_QUIT        => '_QUIT',
   Q_CLOSE       => '_CLOSE',
   TIMEOUT_MSG   => 'Connection idle timeout, bye.',
   GRAPHITE_HOST => '10.58.83.252',
   GRAPHITE_PORT => 2003,
   GRAPHITE_PROT => 'tcp',
};

# Just a simple way of instantiating this class for less typing
my $_singleton;

sub new {
   return $_singleton //= bless({}, shift);
}

1;
__END__
