#!/usr/bin/env perl
# Licence     : GPL
# Author      : Odd Eivind Ebbesen <odd@oddware.net>
# Date        : 2013-10-31 13:05:44
#
# Description :
# Trying out Wx for a GUI, after hitting some bugs with 
# Tkx that made it crash if run in an NX session.

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
use BWMonitor::GUI::Wx::App;


our $VERSION = $BWMonitor::Cmd::VERSION;

my $app = BWMonitor::GUI::Wx::App->new;
$app->MainLoop;


__END__
