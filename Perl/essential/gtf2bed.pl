#!/usr/bin/perl

use strict; use warnings;

my ($input, $output) = @ARGV;
die "usage: $0 <gtf from Ensembl> <output.bed>\n" unless @ARGV == 2;
my %bed;
my %gene;
open (my $in, "<", $input) or die "Cannot read from $input: $!\n";
open (my $out, ">", $output) or die "Cannot write to $output: $!\n";
while (my $line = <$in>) {
	chomp($line);
	my ($chr, $junk0, $junk1, $start, $end, $dot, $strand, $dot2, $name) = split("\t", $line);
	my @name = split(";", $name);
	my $gene_id;
	my $type;
	foreach my $names (@name) {
		$names =~ s/^\s{1,10}//;
		($gene_id) = $names =~ /^gene_id "(.+)"$/ if $names =~ /^gene_id/;
		($type)    = $names =~ /^gene_biotype "(.+)"$/ if $names =~ /^gene_biotype/;
	}
	$type = $junk0 if not defined($type);# and print "Undef type: using $junk0 at $line\n" if not defined($type);
	die "Undef gene_id at $line\n" if not defined($gene_id);
	die "Undef gene_id at $line\n" if $gene_id =~ /^$/;
	if ($type eq "protein_coding") {
		$gene{$gene_id} = 1;
		if (defined($bed{$gene_id}{val})) {
			print "Previous type: $bed{$gene_id}{val}. Current: $type\n" if $bed{$gene_id}{val} ne $type;
			die "$line\n" if $bed{$gene_id}{val} ne $type;
		}
	}
	my $chr_type;
	if ($chr =~ /^\d+$/) {
		$chr_type = "numeric";
	}
	else {
		$chr_type = "alphabet";
	}
	die if not defined($chr_type);
	$bed{$chr_type}{$chr}{$gene_id}{start}  = $start if not defined($bed{$chr_type}{$chr}{$gene_id}{start}) or $start < $bed{$chr_type}{$chr}{$gene_id}{start};
	$bed{$chr_type}{$chr}{$gene_id}{end}    = $end   if not defined($bed{$chr_type}{$chr}{$gene_id}{end})   or $end > $bed{$chr_type}{$chr}{$gene_id}{end}    ;
	$bed{$chr_type}{$chr}{$gene_id}{val}    = $type;
	$bed{$chr_type}{$chr}{$gene_id}{strand} = $strand;
}
close $in;
my $count = 0;
foreach my $chr (sort {$bed{numeric}{$a} <=> $bed{numeric}{$b}} keys %{$bed{numeric}}) {
	foreach my $gene_id (sort {$bed{numeric}{$chr}{$a}{start} <=> $bed{numeric}{$chr}{$b}{start}} keys %{$bed{numeric}{$chr}}) {
		my $start   = $bed{numeric}{$chr}{$gene_id}{start};
		my $end     = $bed{numeric}{$chr}{$gene_id}{end};
		my $val     = $bed{numeric}{$chr}{$gene_id}{val};
		my $strand  = $bed{numeric}{$chr}{$gene_id}{strand};
		print $out "$chr\t$start\t$end\t$gene_id\t$val\t$strand\n";
		$count++ if $val eq "protein_coding";
	}
}
foreach my $chr (sort {$bed{alphabet}{$a} cmp $bed{alphabet}{$b}} keys %{$bed{alphabet}}) {
	foreach my $gene_id (sort {$bed{alphabet}{$chr}{$a}{start} <=> $bed{alphabet}{$chr}{$b}{start}} keys %{$bed{alphabet}{$chr}}) {
		my $start   = $bed{alphabet}{$chr}{$gene_id}{start};
		my $end     = $bed{alphabet}{$chr}{$gene_id}{end};
		my $val     = $bed{alphabet}{$chr}{$gene_id}{val};
		my $strand  = $bed{alphabet}{$chr}{$gene_id}{strand};
		print $out "$chr\t$start\t$end\t$gene_id\t$val\t$strand\n";
		$count++ if $val eq "protein_coding";
	}
}
print "Count = $count\n";