#!/usr/local/bin/perl -w

$infile = "emails.txt";

open(IN, $infile) || die "can't open input file";

$line = <IN>;
chop($line);
$line =~ s/ //g;
($decision, $result) = split(/\//, $line);
@decision_var = split(/\t/,$decision);
@result_var = split(/\t/, $result);

$count =0;

print "sub decision_map {\n";
print "# initialise Decision variables\n";
for($i=0;  $i<=$#decision_var; $i++) {
  print "my \$".$decision_var[$i]." = \$_[$i];\n";
}

print "# initialise Result variables\n";
for($i=0;  $i<=$#result_var; $i++) {
	next if length($result_var[$i])<1;
	print "my \$".$result_var[$i].";\n";
}
print "# loop through decision variables combinations\n";
while($line = <IN>) {
	chop($line);
#	$line =~ s/ //g;
	($decision, $result) = split(/\//, $line);
	@decision_val = split(/\t/,$decision);
	@result_val = split(/\t/, $result);

	if($count++ > 0) {
		print "} elsif (";
	} else {
		print "if (";
	}
	for($i=0; $i<=$#decision_var; $i++) {
		$decision_val[$i] =~ s/^ //;
		$decision_val[$i] =~ s/ $//;
		$decision_val[$i] =~ s/<<blank>>//;
		$decision_val[$i] =~ s/\'/\\'/g;
		print "\$".$decision_var[$i]." =~ \/".$decision_val[$i]."\/";
		if ($i<$#decision_var) {
			print " && ";
		} else {
			print "){\n";
			print "\t";
			for($j=0; $j<=$#result_var; $j++) {
				next if length($result_var[$j])<1;
				print "\$".$result_var[$j]." = \"".$result_val[$j]."\"; ";
			}
			if($j>= $#result_var) {
				print "\n";
			}
		}
	}
}
print "} else { &error_handler();}\n";
print "return (";
for($j=0; $j<=$#result_var; $j++) {
	next if length($result_var[$j])<1;
	print "\$".$result_var[$j];
	print ", " if ($j< $#result_var);
}
print ");\n";
print "} # End of Decision map function - AAAA, Oct 2003\n\n";

close(IN);
exit;
