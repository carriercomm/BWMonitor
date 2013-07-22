# Licence     : GPL
# Author      : Odd Eivind Ebbesen <odd@oddware.net>
# Date        : 2013-07-17 15:48:27
#
# Description :
#   Buffered storage of random data
#

package BWMonitor::Rnd;

use v5.10;
use strict;
use warnings;

# With CHUNK_SIZE set to 16384 and CHUNK_NUM set to 4096, we will
# have 64 MB of random data at any time.
# Adjust as needed.
use constant CHUNK_SIZE    => 16384;
use constant CHUNK_NUM     => 4096; 

our $VERSION = $BWMonitor::Cmd::VERSION;

my @_queue;
my $_urnd_fh;

#sub _genrnd {
#   # Because of the usage of pack(), unsigned long etc, the data returned will be $size X 4
#   # E.g. Size of 4096 will return a 16384 bytes long string.
#   my $size = shift || 4096;
#   #return "." x ($size * 4); # waaaay faster, for when testing other parts of the code
#   return pack('L*', map(rand(~0), 1 .. $size));
#}

sub genrnd {
   my $size = shift || CHUNK_SIZE;
   if (!$_urnd_fh) {
      open($_urnd_fh, "<", '/dev/urandom') or die($!);
   }
   my $len = 0;
   my $buf = '';
   while ($len < $size) {
      $len += sysread($_urnd_fh, $buf, $size);
   }
   return $buf;
}

sub init {
   # Generate CHUNK_NUM chunks of CHUNK_SIZE random bytes to keep in RAM.
   # As this might take a loooong time, one could provide a callback here
   # to print status or something.
   my $cref = shift;
   my $cb = ($cref && ref($cref) && ref($cref) eq 'CODE' ? $cref : undef);
   @_queue = ();    # make sure it's empty
   for (0 .. CHUNK_NUM - 1) {
      push(@_queue, genrnd);
      $cb->() if (defined($cb));
   }
}

sub fillup {
   # Almost like init, but fills only as many slots as needed to get the size 
   # back up to CHUNK_NUM
   my $slots = 0;
   for (scalar(@_queue) .. CHUNK_NUM - 1) {
      push(@_queue, genrnd);
      ++$slots;
   }
   return $slots;
}

sub rotate {
   # take one, give one
   push(@_queue, genrnd);
   return shift(@_queue);
}

sub get {
   # Fast when there's something in the buffer. Won't fail, 
   # but rather slow down if the buffer gets depleated.
   return shift(@_queue) || genrnd;
}

sub clear {
   @_queue = ();
}

sub cleanup {
   undef(@_queue);
   if ($_urnd_fh) {
      close($_urnd_fh) or warn($!);
   }
}


1;
__END__
