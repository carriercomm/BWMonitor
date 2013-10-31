#!/usr/bin/env perl
# Trying out Wx for a GUI, after hitting some bugs with 
# Tkx that made it crash if run in an NX session.
#
# Odd Eivind Ebbesen <odd@oddware.net>, 2013-10-31 13:05:44

package BWM_GUI_WX;

#use strict;
#use warnings;
use Modern::Perl;

use Wx;
use FindBin;
use Data::Dumper;

use lib "$FindBin::Bin/../lib";
use BWMonitor::Cmd;
use BWMonitor::Client;
use BWMonitor::Logger;

use base qw(Wx::App);

our $VERSION = $BWMonitor::Cmd::VERSION;


sub OnInit {
   my $self = shift;

   $self->{frm}{main} = Wx::Frame->new(undef, -1, 'BWMonitor GUI');
   my $mp = $self->{pnl}{main} = Wx::Panel->new($self->{frm}{main});

   #$self->{box}{conn} = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
   #$self->{sbs}{conn} = Wx::StaticBoxSizer->new(&Wx::wxHORIZONTAL);


   $self->{frm}{main}->Show(1);
}


#---
__PACKAGE__->new->MainLoop;


__END__
