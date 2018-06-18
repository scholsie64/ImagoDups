#!/usr/bin/perl

#
# Detect imago images that are stored in both compressed and uncompressed format, often due
# to the database being rsynced from anotehr server at some point.
#

use File::Find;
use Getopt::Long;
use Number::Bytes::Human qw (format_bytes);

$| = 1;
my $totalfiles = 0;
my $startdir = ".";
my $total_dups_saving = 0;
my $total_comp_saving = 0;
my %dups = {};
my $totaldups = 0;
my %nodups = {};
my $totalnodups = 0;
my %dupsnotsame = {};
my $totaldupsnotsame = 0;

if ($ARGV[0] ne "") {
	$startdir = $ARGV[0];
}

find (\&check_dup, $startdir);

sub check_dup {
	if (-f && /f*[0-9]$/) {	# Check for uncompressed image file, starts with f, ends with digit.
		$totalfiles++;

		my $compver = $_ . ".gz";
		if ( -f $compver) { # is there a compressed version as well.

			system "gunzip -c $compver > /tmp/dups";

			if (!system "cmp -s /tmp/dups $_") {
				$totaldups++;
				$dups{$_} = -s $_;
				$total_dups_saving += $dups{$_};
				#printf "File '%s' is uncommpressed and a compressed version of it exists, so it is duplicated\n", $File::Find::name;
			} else {
				#printf "File '%s' is uncommpressed and a compressed file exists BUT it is not a compressed version of it\n", $File::Find::name;
				$totaldupsnotsame++;
				$dupsnotsame{$_} = -s $_;	
			}

		} else {
			$totalnodups++;
			system "gzip -c $_ > /tmp/dups";
			$nodups{$_} = -s "/tmp/dups";
			$total_comp_saving += -s $_;
			$total_comp_saving -= $nodups{$_};
			#printf "File '%s' is uncompressed and NO compressed version of it exists, so it could be compressed\n", $File::Find::name;
		}
	}
	printf "Total:- %d  Duplicates(Same):- %d Duplicates(Different):- %d Uncompressed:- %d\r", $totalfiles, $totaldups, $totaldupsnotsame, $totalnodups;
}

printf "\n\nTotal disc space saved by deleting uncompressed duplicates = %s\n", format_bytes ($total_dups_saving);
printf "Total disc space saved by compressing uncompressed files = %s\n", format_bytes ($total_comp_saving);
