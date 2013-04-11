#!/usr/bin/env perl
# Licence: GPL
# Author: Odd Eivind Ebbesen <odd@oddware.net>
# Date: 2013-04-04 15:48:04

use strict;
use warnings;

use POSIX ();
use IO::File;
use Getopt::Long qw(:config gnu_getopt auto_help auto_version);
use BWMonitor::Logger;
use BWMonitor::ProtocolCommand;
use BWMonitor::Server;

my $logger = BWMonitor::Logger->new();
my $pcmd   = BWMonitor::ProtocolCommand->new();

my $opts = {
   ctrl_port   => $pcmd->SERVER_PORT,
   data_port   => $pcmd->DATA_PORT,
   config_file => undef,
};

GetOptions(
   'config_file=s' => \$opts->{config_file},
   'ctrl_port=i'   => \$opts->{ctrl_port},
   'data_port=i'   => \$opts->{data_port},
   'help|?'        => \$opts->{help},
);

my $server = BWMonitor::Server->new(pcmd => $pcmd, logger => $logger, data_port => $opts->{data_port});
$server->run(conf_file => $opts->{config_file}, port => $opts->{ctrl_port});

