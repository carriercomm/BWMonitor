# Licence     : GPL
# Author      : Odd Eivind Ebbesen <odd@oddware.net>
# Date        : 2013-07-16 11:31:41
#
# Description :
#   Module with commands/constants etc shared by other modules in this App.
#

package BWMonitor::Cmd;

use v5.10;
use strict;
use warnings;

use Carp;

our $VERSION = '2013-07-19';

use constant {
   TIMEOUT             => 5,
   PORT                => 3389,                   # TCP port to listen on
   S_BUF               => 16384,                  # buffer size, in bytes
   S_DATA              => 1_048_576 * 10,         # data/sample size, in bytes (10 MB)
   NL                  => "\n",
   PROTO               => 'tcp',
   XXX                 => undef,
   GRAPHITE_HOST       => '10.57.78.24',          #'10.58.83.252',
   GRAPHITE_PORT       => 2003,
   GRAPHITE_PROTO      => 'tcp',
   GRAPHITE_RES_PREFIX => 'bwmonitor.results.',
};

use constant {
   Q_SET_SIZES => qr/^_SETS\s+(\d+)\s+(\d+)/,                             # KW, sample size, buffer size
   Q_LOG       => qr/^_LOG\s+(\d+)\s+(\d*\.?\d+)\s+([\d\._]+)\s+(.*)/,    # KW, bytes, seconds, host, free text
   Q_DL        => '_DOWNLOAD',
   Q_QUIT      => '_QUIT',
   Q_CLOSE     => '_CLOSE',
   A_ACK       => '_ACK',
   TIMEOUT_MSG => 'Connection idle timeout, bye.',
};

###

my $_disp_tbl = {
   q => {
      set_sizes => sub {
         my $size_data = shift;
         my $size_buf  = shift;
         return sprintf("_SETS %d %d", $size_data, $size_buf);
      },
      log => sub {
         my $bytes   = shift;
         my $seconds = shift;
         my $host    = shift;
         my $msg     = shift || '';
         $host =~ s/\./_/g;
         return sprintf("_LOG %d %f %s %s", $bytes, $seconds, $host, $msg);
        },
   },
};

sub new {
   state $self; # requires v5.10+
   return $self //= bless({}, shift);
}

sub _q {
   my $self = shift;
   my $href = shift // $_disp_tbl;    # call first time with undef

   while (my $k = shift(@_)) {
      my $type = ref($href->{$k});
      if ($type eq 'HASH') {
         return $self->_q($href->{$k}, @_);
      }
      elsif ($type eq 'CODE') {
         return $href->{$k}->(@_);
      }
   }
   return undef;    # if we got here, the path was wrong and nothing defined
}

sub q {
   return shift->_q(undef, @_);
}

1;
__END__
