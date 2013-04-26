#!/usr/bin/env perl
# Licence: GPL
# Author: Odd Eivind Ebbesen <odd@oddware.net>
# Date: 2013-04-08 11:24:25

use strict;
use warnings;
use feature ':5.10';

use Carp;
use Getopt::Long qw(:config auto_help auto_version no_ignore_case);
use Pod::Usage;
use Data::Dumper;
use BWMonitor::ProtocolCommand;
use BWMonitor::Client;

$main::VERSION = '2013-04-26';

my $pcmd = BWMonitor::ProtocolCommand->new();
my $opts = {
   port      => $pcmd->SERVER_PORT,
   data_port => $pcmd->DATA_PORT,
};

GetOptions(
   'host=s'      => \$opts->{host},
   'port=i'      => \$opts->{port},
   'data_port=i' => \$opts->{data_port},
   'help|?'      => \$opts->{help},
   'man'         => \$opts->{man},
   'version|V'   => sub { Getopt::Long::VersionMessage(0) },
) or croak($!);

pod2usage(-verbose => 1) && exit(0) if ($opts->{help});
pod2usage(-verbose => 2) && exit(0) if ($opts->{man});

if (!$opts->{host}) {
   croak("Error! Please specify a host to connect to!");
}

my $client = BWMonitor::Client->new(
   remote_host   => $opts->{host},
   remote_port_c => $opts->{port},
   remote_port_d => $opts->{data_port},
);

my $buf;
$client->connect or croak($!);
#$client->send("This is a little test");
$buf = $client->recv;
print("Server said: $buf\n");
my $result = $client->download;
printf("Got: %s\n", Dumper($result)) if ($result);
#printf("End info: %s", $client->recv);
$client->disconnect;

__END__

=pod

=head1 NAME

B<bwm_client> - Bandwidth Monitor Client

=head1 DESCRIPTION

This is the client part of the BWMonitor package. This script is just
a small wrapper to initiate BWMonitor::Client and run one measurement
test and upload the result back to the server.

=head1 SYNOPSIS

C<< bwm_client.pl --host < hostname | ip > [ options ] >>

=head1 OPTIONS

=over

=item B<< --host <hostname> >>

The remote hostname or IP of the BWMonitor server to connect to.

=item B<< --port <port> >>

The remote TCP port of the BWMonitor server control channel. Default: B<10443>

=item B<< --data_port <port> >>

The remote TCP port for iperf backend. Default: B<10444>

=item B<< --help >>

This message, to STDOUT.

=item B<< --man >>

The full POD documentation formatted as a man page, piped to C<< $PAGER >>

=back

=head1 AUTHOR

Odd Eivind Ebbesen

