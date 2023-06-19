#!/usr/bin/perl -w
use strict;
use warnings;

my $colName = $ARGV[0];
my $fileName = $ARGV[1];

if ($fileName =~ /.gz$/) {
	open(FILE, "gunzip -c $fileName |");
} else {
	open(FILE, "<", $fileName);
}

my $header = <FILE>;
chomp($header);
my @fields = split(/[\t ]/, $header);
close(FILE);

my ($index) = grep { CORE::fc($fields[$_]) eq CORE::fc($colName) } (0 .. @fields-1);
if (defined $index) {
	print $index;
} else {
	print "-1";
}
