# Licence: GPL
# Author: Odd Eivind Ebbesen <odd@oddware.net>
# Date: 2013-02-26 23:28:46

package BWMonitor::ProtocolCommand;

use strict;
use warnings;
use feature ':5.10';

our $VERSION = '2013-04-29';

use constant {
   TIMEOUT             => 5,
   SERVER_PORT         => 10443,
   DATA_PORT           => 10444,
   NL                  => "\012\015",
   TIMEOUT_MSG         => 'Connection idle timeout, bye.',
   GRAPHITE_HOST       => '10.58.83.252',
   GRAPHITE_PORT       => 2003,
   GRAPHITE_PROT       => 'tcp',
   GRAPHITE_RES_PREFIX => 'bwmonitor.results.',
   Q_QUIT              => '_QUIT',
   Q_CLOSE             => '_CLOSE',
   Q_CSV               => '_RESULT_CSV',
   R_CSV               => qr/\A_RESULT_CSV\s+([a-zA-Z0-9_-]+)\s+(\d+)\s+(.*)\Z/,
};

# Just a simple way of instantiating this class for less typing
my $_singleton;

sub new {
   return $_singleton //= bless({}, shift);
}

1;
__END__
