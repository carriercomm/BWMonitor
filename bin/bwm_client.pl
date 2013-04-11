#!/usr/bin/env perl
# Licence: GPL
# Author: Odd Eivind Ebbesen <odd@oddware.net>
# Date: 2013-04-08 11:24:25

use strict;
use warnings;

use Carp;
use Getopt::Long qw(:config gnu_getopt auto_help auto_version);
use BWMonitor::ProtocolCommand;
use BWMonitor::Client;

my $pcmd = BWMonitor::ProtocolCommand->new();
my $opts = {
   port      => $pcmd->SERVER_PORT,
   data_port => $pcmd->DATA_PORT,
};

GetOptions(
   'host=s'      => \$opts->{host},
   'port=i'      => \$opts->{port},
   'data_port=i' => \$opts->{data_port},
) or croak($!);

if (!$opts->{host}) {
   croak("Error! Please specify a host to connect to!");
}

my $client = BWMonitor::Client->new(
   remote_host   => $opts->{host},
   remote_port_c => $opts->{port},
   remote_port_d => $opts->{data_port},
);

my $buf;
$client->connect or croak;
#$client->send("This is a little test");
$buf = $client->recv;
print("Server said: $buf\n");
my $result = $client->download;
print("Got: $result\n") if ($result);
$client->disconnect;
