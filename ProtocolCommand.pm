# Licence: GPL
# Author: Odd Eivind Ebbesen <odd@oddware.net>
# Date: 2013-02-26 23:28:46

package ProtocolCommand;

use strict;
use warnings;

our $VERSION = '0.0.1';

use constant {
   PROTO       => 'tcp',
   BUF_LEN     => 4096,
   TIMEOUT     => 5,
   SERVER_PORT => 10443,
};

1;
__END__
