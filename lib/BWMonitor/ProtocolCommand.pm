# Licence: GPL
# Author: Odd Eivind Ebbesen <odd@oddware.net>
# Date: 2013-02-26 23:28:46

# Notes
# GET size_bytes buf_size
# PUT size_bytes buf_size

package BWMonitor::ProtocolCommand;

use strict;
use warnings;

our $VERSION = '0.0.4';

use constant {
   TIMEOUT     => 5,
   SERVER_PORT => 10443,
   DATA_PORT   => 10444,
   BUF_SIZE    => 4096,
   SAMPLE_SIZE => 1_048_576,    # 1MB
   MAGIC       => 0x0DDEE,
   HANDSHAKE   => 0x0666,
   NL          => "\012\015",
};

# Just saving for (possibly later)
#(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\s+    # ip, dotted notation + space(s)

use constant {
   # "question"
   Q_GET => qr/
         ^_GET\s+                                   # keyword + space(s)
         (\d+)\s+                                   # bytes
         (\d+)                                      # buffer size
      /x,
   # "answer"
   A_GET => qr/
         ^_GET_OK\s+                                # keyword + space(s)
         (\d+)\s+                                   # size in bytes + space(s)
         (\d+)\s+                                   # buf size in bytes + space(s)
         (\d{4,5})                                  # port, 4-5 digits
      /x,
   # "result"
   R_GET => qr/
         ^_GET_RESULT\s+                            # keyword + space(s)
         (\d+)\s+\w+\s+\w+\s+                       # xxx bytes in
         (\d*\.?\d+)                                # xxx.xx seconds
      /x,
   Q_HELLO     => qr/^_HELLO\s+(\d+)/,
   Q_QUIT      => '_QUIT',
   Q_CLOSE     => '_CLOSE',
   A_OK        => '_OK',
   A_NOK       => '_NOT_OK',
   TIMEOUT_MSG => 'Connection idle timeout, bye.',
};

# helper subs to make generating correctly formatted questions/answers easier
our $_SUB = {
   get => {
      q => sub {
         my $size     = shift || SAMPLE_SIZE;
         my $buf_size = shift || BUF_SIZE;
         return sprintf("_GET %d %d", $size, $buf_size);
      },
      a => sub {
         my $port     = shift;
         my $bytes    = shift || SAMPLE_SIZE;
         my $buf_size = shift || BUF_SIZE;
         return sprintf("_GET_OK %d %d %d", $bytes, $buf_size, $port);
      },
      r => sub {
         my ($bytes, $seconds) = @_;
         return sprintf("_GET_RESULT %d bytes in %f seconds", $bytes, $seconds);
      },
   },
   hello => { q => sub { return sprintf("_HELLO %d", MAGIC); } },
};


# Just a simple way of instantiating this class for less typing
my $_singleton;
sub new {
   return $_singleton //= bless({}, shift);
}

sub _sub {
   my $self = shift;
   my $l1 = shift;
   my $l2 = shift;
   
   if (exists($_SUB->{$l1}{$l2}) && ref($_SUB->{$l1}{$l2}) eq 'CODE') {
      return $_SUB->{$l1}{$l2}->(@_);   # exec sub ref with whatever args given
   }
   return undef;
}


1;
__END__
