#!/usr/bin/env perl
# Licence     : GPL
# Author      : Odd Eivind Ebbesen <odd@oddware.net>
# Date        : 2013-07-18 19:17:23
#
# Description :
#   Argument parsing frontend script for starting an instance 
#   of BWMonitor::Server.
#

use v5.10;
use strict;
use warnings;

use Getopt::Long;

use lib '../lib';
use BWMonitor::Cmd;
use BWMonitor::Server;

my $_opts = {
   port           => BWMonitor::Cmd::PORT,
   graphite_host  => BWMonitor::Cmd::GRAPHITE_HOST,
   graphite_port  => BWMonitor::Cmd::GRAPHITE_PORT,
   graphite_proto => BWMonitor::Cmd::GRAPHITE_PROTO,
};

GetOptions(
   'port=i'             => \$_opts->{port},
   'graphite'           => \$_opts->{graphite},
   'graphite_host|gh=s' => \$_opts->{graphite_host},
   'graphite_port|gp=s' => \$_opts->{graphite_port},
   'graphite_proto=s'   => \$_opts->{graphite_proto},
   'help|?'             => sub { print("Help...\n"); }
) or die($!);

BWMonitor::Server->new(
   enable_graphite => $_opts->{graphite},
   graphite_host   => $_opts->{graphite_host},
   graphite_port   => $_opts->{graphite_port},
   graphite_proto  => $_opts->{graphite_proto},
  )->run(
   port => $_opts->{port}, 
   log_level => 4
);

__END__


