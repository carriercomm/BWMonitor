#!/usr/bin/env perl
# Licence     : GPL
# Author      : Odd Eivind Ebbesen <odd@oddware.net>
# Date        : 2013-10-31 15:48:12
#
# Description :
# Wx Application object

use Modern::Perl;

package BWMonitor::GUI::Wx::App;

use Wx;

use BWMonitor::Cmd;
use BWMonitor::GUI::Wx::MainFrame;

use base qw(Wx::App);

our $VERSION = $BWMonitor::Cmd::VERSION;

my %_frm;

sub OnInit {
   my $self = shift;
   $_frm{$self} = BWMonitor::GUI::Wx::MainFrame->new;
   $_frm{$self}->Show;
   return 1;
}

sub DESTROY {
   my $self = shift;
   delete($_frm{$self});
}

1;
__END__
