#!/usr/bin/env perl

use strict;
use warnings;

use Perl::PrereqScanner;
use Data::Dumper;

my $scanner = Perl::PrereqScanner->new;
my $prereqs = $scanner->scan_file(shift);

print(Dumper($prereqs->as_string_hash));
