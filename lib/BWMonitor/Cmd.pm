# Licence: GPL
#
# Module with commands/constants etc shared by other modules in this App.
#
# Odd, 2013-07-16 11:31:41

package BWMonitor::Cmd;

use v5.10;
use strict;
use warnings;

use Carp;
#use Scalar::Util;

our $VERSION = '2013-07-16';

use constant {
   TIMEOUT => 5,
   PORT    => 10443,        # TCP port to listen on
   S_BUF   => 16384,        # buffer size, in bytes
   S_DATA  => 1_048_576,    # data/sample size, in bytes (1MB)
   NL      => "\n",
   PROTO   => 'tcp',
   XXX     => undef,
};

use constant {
   Q_SET_SIZES => qr/^_SETS\s+(\d+)\s+(\d+)/,                # KW, sample size, buffer size
   Q_LOG       => qr/^_LOG\s+(\d+)\s+(\d*\.?\d+)\s+(.*)/,    # KW, bytes, seconds, free text
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
         my $msg     = shift;
         return sprintf("_LOG %d %f %s", $bytes, $seconds, $msg);
      },
   },
   test => {
      lvl1 => {
         lvl2  => sub { return "Got: @_"; },
         kjell => "bille",
         num   => 40,
      },
      mf => "hest",
   }
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
   my $self = shift;
   return $self->_q(undef, @_);
}
