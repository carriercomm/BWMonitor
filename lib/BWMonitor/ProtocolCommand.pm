# Licence: GPL
# Author: Odd Eivind Ebbesen <odd@oddware.net>
# Date: 2013-02-26 23:28:46

# Notes
# GET size_bytes buf_size
# PUT size_bytes buf_size

package BWMonitor::ProtocolCommand;

use strict;
use warnings;

our $VERSION = '0.0.2';

use constant {
   TIMEOUT     => 5,
   SERVER_PORT => 10443,
   DATA_PORT   => 10444,
   BUF_SIZE    => 4096,
   SAMPLE_SIZE => 1_048_576,   # 1MB
};

1;
__END__
