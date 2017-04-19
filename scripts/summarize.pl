use warnings;
use strict;
my $usage = "perl summarize.pl <loc> <sampleinfo>

[options]
-original <original>


";
if (@ARGV<2){
    die $usage;
}

my $loc = $ARGV[0];
my $sampleinfo = $ARGV[1];

my $goal;
my $Pval = "false"; # set it to true if orginal div is given
for(my $i=2;$i<@ARGV;$i++){
    my $option_rec = "false";
    if ($ARGV[$i] eq "-original"){
        $goal = $ARGV[$i+1];
        $Pval = "true";
        $i++;
        $option_rec = "true";
    }
    unless ($option_rec eq "true"){
        die "ERROR: option $ARGV[$i] not recognized\n";
    }
}

open(IN, $sampleinfo) or die "ERROR: cannot open $sampleinfo\n";
my $h = <IN>;
chomp($h);
my %SCOL;
my $c_cnt = 0;
while(my $line = <IN>){
    chomp($line);
    my ($sample, $cond);
    if ($Pval eq "true"){
	($sample, $cond) = split(/\t/,$line);
    	$SCOL{$c_cnt} = "$cond.$sample";
    }
    else{
	$sample = $line;
    	$SCOL{$c_cnt} = "$sample";
    }
    $c_cnt++;
}
close(IN);

my $pout = "$loc/decaf_output_optimal_divisions.txt";
my $min_pout = "$loc/decaf_output_min_score.txt";
my $out = "$loc/decaf_output_optimal_divisions.txt";
if ($Pval eq "true"){ 
    open(POUT, ">$pout");
    open(MPOUT, ">$min_pout");
}
else{
    open(OUT, ">$out");
}

my @conf = (0.5, 0.55,0.6,0.65,0.7,0.75,0.8,0.85,0.9,0.95);
if ($Pval eq "true"){
    my $goal_div = &getDiv($goal);
    my $len = length($goal_div);
    print POUT "-" x $len;
    print POUT "\n";
    print POUT "$goal_div\n";
    print POUT "-" x $len;
    print POUT "\n";
    print POUT "fdr\tp-val\tratio\tscore\tOptimalDiv\n";

    print MPOUT "-" x $len;
    print MPOUT "\n";
    print MPOUT "$goal_div\n";
    print MPOUT "-" x $len;
    print MPOUT "\n";
    print MPOUT "fdr\tp-val\tratio\tscore\tOptimalDiv\n";

}
else{
    print OUT "fdr\tOptimalDiv\n";
}

my $minS = 100;
my $minFdr=100;
my ($minOdiv,$minR,$minP);
foreach my $f (@conf){
    my $final = "$loc/final.$f.txt";
    my $lc = `wc -l $final`;
    chomp($lc);
    my @c = split(" ", $lc);
    my $total = $c[0];
    my $unperm_cnt;
    if ($Pval eq "true"){
    	my $x = `grep -w $goal $final`;
    	chomp($x);
    	my @a = split(/\t/, $x);
    	$unperm_cnt = $a[1];
    }
    my $rank = 0;
    my $max = 0;
    my $maxstring="";
    open(FIN, $final);
    while(my $line = <FIN>){
    	chomp($line);
	my @a = split(" ", $line);
	my $cnt = $a[1];
	if ($Pval eq "true"){
	    if ($cnt >= $unperm_cnt){
	    	$rank++;
	    }
	}
	if ($cnt > $max){
	    $max = $cnt;
	    $maxstring = $a[0];
	}
    }
    close(FIN);
    my $odiv = &getDiv($maxstring);
    my $fdr = 1-$f;
    if ($Pval eq "true"){
    	my $p = ($rank/$total);
    	$p = sprintf ("%.4f", $p);
	my ($score, $ratio);
	if (($unperm_cnt == 0) || ($max == 0)){ # avoid dividing by 0
	    $ratio = 0;
	    $score = 1;
	}
	else{
            $ratio = ($unperm_cnt/$max);
	    $score = ($p/$ratio);
	}
	if ($score > 1){ # maximum score = 1
	    $score = 1;
	}
	$ratio = sprintf("%.4f", $ratio);
	$score = sprintf("%.4f", $score);
	if ($score <= $minS){ # find div with smallest score
	    if ($score == $minS){ # if there's a tie report the division with smallest fdr
		if ($fdr < $minFdr){
        	    $minFdr = $fdr;
		    $minOdiv = $odiv;
	    	}
	    }
	    else{
		$minS = $score;
        	$minFdr = $fdr;
		$minOdiv = $odiv;
		$minP = $p;
		$minR = $ratio;
	    }
	}
    	print POUT "$fdr\t$p\t$ratio\t$score\t$odiv\n";
    }
    else{
    	print OUT "$fdr\t$odiv\n";
    }
}
if ($Pval eq "true"){
    close(POUT);    
    print MPOUT "$minFdr\t$minP\t$minR\t$minS\t$minOdiv\n";
    close(MPOUT);
}
else{
    close(OUT);
}

sub getDiv {
    my ($string) = @_;
    my $colN = 0;
    my %CONDS;
    foreach my $cond (split //, $string){
	my $sampleid = $SCOL{$colN};
	$colN++;
	if (exists $CONDS{$cond}){
	    $CONDS{$cond} .= ", $sampleid";
	}
	else{
	    $CONDS{$cond} = $sampleid;
	}
    }
    return "[".$CONDS{0}."],[".$CONDS{1}."]";

}

