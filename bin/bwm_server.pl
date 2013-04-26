#!/usr/bin/env perl
# Licence: GPL
# Author: Odd Eivind Ebbesen <odd@oddware.net>
# Date: 2013-04-04 15:48:04

use strict;
use warnings;
use feature ':5.10';

use Carp;
use Getopt::Long qw(:config auto_help auto_version no_ignore_case);
use Pod::Usage;
use BWMonitor::ProtocolCommand;
use BWMonitor::Server;

$main::VERSION = '2013-04-26';

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
   'man'           => \$opts->{man},
   'version|V'     => sub { Getopt::Long::VersionMessage(0) },
) or croak($!);

pod2usage(-verbose => 1) && exit(0) if ($opts->{help});
pod2usage(-verbose => 2) && exit(0) if ($opts->{man});

my $server = BWMonitor::Server->new(pcmd => $pcmd, data_port => $opts->{data_port});
$server->run(conf_file => $opts->{config_file}, port => $opts->{ctrl_port});

__END__

=pod

=head1 NAME

B<bwm_server> - Bandwidth Monitor Server

=head1 DESCRIPTION

This is the server part of the BWMonitor package. This script is just
a small wrapper to initiate BWMonitor::Server and start listening for 
requests and serving them.

=head1 SYNOPSIS

C<< bwm_server.pl [ options ] >>

=head1 OPTIONS

=over

=item B<< --config_file </path/to/file.cfg >>

Optional configuration file for C<< Net::Server >> which C<< BWMonitor::Server >> is based on. 
See the documentation for C<< Net::Server >> for possible options and format.

=item B<< --ctrl_port <port> >>

The TCP port on which the server should listen for new clients to send commands. Default: B<10443>

=item B<< --data_port <port> >>

The TCP port for which iperf server instances should listen. Default: B<10444>

=item B<< --help >>

This message, to STDOUT.

=item B<< --man >>

The full POD documentation formatted as a man page, piped to C<< $PAGER >>

=item B<< --version | -V >>

Prints the version for this script and the running Perl.

=back

=head1 AUTHOR

Odd Eivind Ebbesen


