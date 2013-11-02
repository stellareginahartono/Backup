#!/usr/bin/perl
# This script is to get sequence from requested ID from biomart ensembl 
# Then download the gene plus 500bp upstream of promoter

use strict; use warnings; use mitochy; use FAlite;

die "usage: R_biomart_getsequence.pl <all | id from R_biomart_gethomolog.pl>\n" unless @ARGV == 1;
my ($input) = @ARGV;

my ($core, $org);
my $mart;
my @datasets;
if ($input ne "all") {
	($core, $org) = $input =~ /(\w+)\.id\.(\w+)\.ID/;
	($core, $org) = $input =~ /(\w+)\.id\.(\w+)\.ID.new.ID/ if not defined($org);
	$mart = "ensembl" if $core =~ /hsapiens/;
	$mart = "plants" if $core =~ /athaliana/;
	$mart = "fungi" if $core =~ /scerevisiae/;
	$mart = "metazoa" if $core =~ /celegans/;
	$mart = "protists" if $core =~ /tgondii/;

	my @datasets = mitochy::get_biomart_dataset($mart);
	#Processing gene ID that you want
	my $geneid;
	open (my $in2, "<", $input) or die "1. Cannot read from $input: $!\n";
	while (my $line = <$in2>) {
		chomp($line);	
		next if $line =~ /Ensembl/;
		$line =~ s/"//ig;
		my @arr = split(" ", $line);
		print "$input: Not defined gene id (probably orth map not made yet)\n" and exit if not defined($arr[2]);
		$geneid .= "\"$arr[2]\",";

	}
	print "$input: Not defined gene id (probably orth map not made yet)\n" and exit if not defined($geneid);
	$geneid =~ s/,$//;
	
	close $in2;
	run_query($core, $org, $mart, $geneid, \@datasets);
}
else {
	my %org = %{mitochy::Global_Var("orglist")};
	foreach my $family (keys %org) {
		print "$family\n";
		($core, $mart) = ("hsapiens","ensembl") if $family =~ /chordate/i;
		($core, $mart) = ("athaliana","plants") if $family =~ /plants/i;
		($core, $mart) = ("scerevisiae","fungi") if $family =~ /fungi/i;
		($core, $mart) = ("celegans","metazoa") if $family =~ /metazoa/i;
		($core, $mart) = ("tgondii","protists") if $family =~ /protists/i;
		@datasets = mitochy::get_biomart_dataset($mart);
		foreach my $org (@{$org{$family}}) {
			run_query($core, $org, $mart, "", \@datasets);
		}	
	}
}

sub run_query {
	my ($core, $org, $mart, $geneid, $datasetarray) = @_;
	exit if not defined($geneid);
	my @dataset = @{$datasetarray};
	#Load library biomaRt
	my $biomart = "library(biomaRt)\n\n";
	#print "GENEID\n$geneid\n";
	$biomart .= "core.mart <-useMart(\"ensembl\", dataset = \"$org\_gene_ensembl\")\n" if $core =~ /hsapiens/;
	$biomart .= "core.mart <-useMart(\"plants_mart_19\", dataset = \"$org\_eg_gene\")\n" if $core =~ /athaliana/;
	$biomart .= "core.mart <-useMart(\"fungi_mart_19\", dataset = \"$org\_eg_gene\")\n" if $core =~ /scerevisiae/;
	$biomart .= "core.mart <-useMart(\"metazoa_mart_19\", dataset = \"$org\_eg_gene\")\n" if $core =~ /celegans/;
	$biomart .= "core.mart <-useMart(\"protists_mart_19\", dataset = \"$org\_eg_gene\")\n" if $core =~ /tgondii/;
	
	#Load requested human gene ID
	$biomart .= "core.geneid <- c($geneid)\n\n";
	$biomart =~ s/, \)/\)/i;
	
	#my $biomart = "library(biomaRt)\n\n";
	$biomart .= "$org.TLSS <- getBM(mart = core.mart, attributes = c(\"chromosome_name\", \"ensembl_gene_id\", \"start_position\", \"end_position\", \"genomic_coding_start\", \"genomic_coding_end\", \"strand\"), checkFilters=FALSE, filters = c(\"ensembl_gene_id\") ,values = list(core.geneid))\n" if $geneid =~ /\w+/;
	$biomart .= "\n\nwrite.table($org.TLSS,file=\"$org.TLS.txt\",sep=\"\t\")\n";
		#Write all the sequence to fast
	
	open (my $out, ">", "$input.$org.TLSS.R") or die "Cannot write to $input.$org.TLSS.R: $!\n";
	print $out "$biomart";
	close $out;
	
#my $Rthis = "R --vanilla --no-save < $input.$org.geneplusflank.R";
#system($Rthis) == 0 or push(@failures, "$input.$org.geneplusflank.R");

#my @failure2;
#if (@failures > 0) {
#	print "Failed to run:\n";
#	foreach my $failed (@failures) {
#		print "$failed\n";
#	}	
#	print "Trying to download the 2nd time...\n";
#	foreach my $failed (@failures) {
#		print "Trying $failed...\n";
#		my $Rthis = "R --vanilla --no-save < $failed";
#		system($Rthis) == 0 or push (@failure2, $failed);
#	}
#}
#my @failure3;
#if (@failure2 > 0) {
#	print "Trying to download the 3rd time...\n";
#	foreach my $failed (@failure2) {
#	        print "Trying $failed...\n";
#	        my $Rthis = "R --vanilla --no-save < $failed";
#	        system($Rthis) == 0 or push (@failure3, $failed);
#	}
#}
#if (@failure3 > 0) {	
#	print "Failed download after 3 tries:\n";
#	foreach my $failed (@failure3) {
#		print "$failed\n";
#	}
#}
}
#print "$biomart\n";

#Write R script to file $input.seq.R
#open (my $out2, ">", "$input.seq.R") or die "Cannot write to $input.seq.R: $!\n";
#print $out2 "$biomart\n";
#close $out2;

#Run R
#if (defined($opt) and $opt =~ /^R2$/) {
#	my $Rthis = "R --vanilla --no-save < $input.seq.R";
#	system($Rthis) == 0 or die "Failed to run R: $!\n";
#}
__END__
