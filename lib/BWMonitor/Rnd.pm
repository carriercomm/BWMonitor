# Licence: GPL
# Odd, 2013-07-17 15:48:27

package BWMonitor::Rnd;

use strict;
use warnings;

#use AnyEvent;

# With CHUNK_SIZE set to 16384 and CHUNK_NUM set to 4096, we will
# have 64 MB of random data at any time.
use constant CHUNK_SIZE    => 16384;
use constant CHUNK_NUM     => 64; # 4096 might be too much
#use constant STATE_BASE    => 0x0001;
#use constant STATE_WORKING => STATE_BASE << 1;
#use constant STATE_READY   => STATE_BASE << 2;
use constant RND_FILE => '/tmp/bwmonitor.rnd';

my @_queue;

sub genrnd {
   # Because of the usage of pack(), unsigned long etc, the data returned will be $size X 4
   # E.g. Size of 4096 will return a 16384 bytes long string.
   my $size = shift || 4096;
   #return "." x ($size * 4); # waaaay faster, for when testing other parts of the code
   return pack('L*', map(rand(~0), 1 .. $size));
}

sub init_rnd_file {
   my $file      = shift || RND_FILE;
   my $size_buf  = shift || 4096;
   my $size_data = shift || 1_048_576 * 64;
   open(my $fh, ">", $file) or die($!);
   my $written = 0;
   while ($written < $size_data) {
      print($fh genrnd($size_buf));
      $written += ($size_buf * 4); # see explanation in genrnd()
   }
   close($fh) or die($!);
}

sub init {
   # Generate CHUNK_NUM chunks of CHUNK_SIZE random bytes to keep in RAM.
   # As this might take a loooong time, one could provide a callback here
   # to print status or something.
   my $cref = shift;
   my $cb = ($cref && ref($cref) && ref($cref) eq 'CODE' ? $cref : undef);
   for (0 .. CHUNK_NUM - 1) {
      push(@_queue, genrnd);
      $cb->() if (defined($cb));
   }
}

sub fillup {
   # Almost like init, but fills only as many slots as needed to get the size 
   # back up to CHUNK_NUM
   for (scalar(@_queue) .. CHUNK_NUM - 1) {
      push(@_queue, genrnd);
   }
}

sub rotate {
   push(@_queue, genrnd);
   return shift(@_queue);
}

sub get {
   return shift(@_queue);
}

### OO subs

#sub new {
#   my $class = shift;
#   my %args  = @_;
#   my %cfg = (
#   );
#   # merge args with cfg
#   @cfg{ keys(%args) } = values(%args);
#
#   return bless(\%cfg, $class);
#}


1;
__END__
