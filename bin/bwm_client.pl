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
   port        => $pcmd->SERVER_PORT,
   sample_size => $pcmd->SAMPLE_SIZE,
   buf_size    => $pcmd->BUF_SIZE,
};

GetOptions(
   'host=s'        => \$opts->{host},
   'port=i'        => \$opts->{port},
   'sample-size=i' => \$opts->{sample_size},
   'buf-size=i'    => \$opts->{buf_size},
) or croak($!);

if (!$opts->{host}) {
   croak("Error! Please specify a host to connect to!");
}

my $client = BWMonitor::Client->new(
   remote_host => $opts->{host},
   remote_port => $opts->{port},
   sample_size => $opts->{sample_size},
   buf_size    => $opts->{buf_size}
);

my $buf;
$client->connect or croak($!);
#$client->send("This is a little test");
$buf = $client->recv;
print("Server said: $buf\n");
my $speed = $client->download;
print("Downloaded at $speed Mbit/s\n") if ($speed);
$client->disconnect;
