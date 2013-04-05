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
use BWMonitor::Producer;
use BWMonitor::Consumer;
use BWMonitor::Server;

my $logger = BWMonitor::Logger->new();
my $pcmd   = BWMonitor::ProtocolCommand->new();

my $opts = {
   tcp_port    => $pcmd->SERVER_PORT,
   udp_port    => $pcmd->DATA_PORT,
   config_file => undef,
};

GetOptions(
   'config_file=s' => \$opts->{config_file},
   'tcp_port=i'    => \$opts->{tcp_port},
   'udp_port=i'    => \$opts->{udp_port},
   'help|?'        => \$opts->{help},
);

my $server = BWMonitor::Server->new(pcmd => $pcmd, logger => $logger, udp_port => $opts->{udp_port});
$server->run(conf_file => $opts->{config_file}, port => $opts->{tcp_port});

