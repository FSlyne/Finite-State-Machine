#! /usr/bin/perl

$root = $ARGV[0];
open(OUT, ">statechanges_fsm.pm") || die "can't open fsm output file";
open(LOG, ">statechanges_fsm.log") || die "can't open fsm log file";
&print_head;
print LOG "processing input fsm files\n";
while($root = <*_fsm\.dat>) {
print LOG "\t$root\n";
open(FSM, $root) || die "can't open input file";
&init;
$section ="Undefined";
while(<FSM>) {
  chop; chop;
	if (/^Name/) {
		$section = "Name";
		next;
	}
	if (/^IndependentVariables/) {
		$line = 0;
		$section = "IV";
		next;
	}
	if (/^StateVariables/) {
		$line =0;
		$section = "SV";
		next;
	}
	if (/^StateTable/){
		$section = "State";
		next;
	}
	if (/^Header/) {
		$line = 0;
		$section = "Header";
		next;
	}

	if (/^Footer/) {
		$line = 0;
		$section = "Footer";
		next;
	}
	if (/^Macros/) {
		$section = "Macro";
		next;
	}

        if($section =~/Header/) {
                $H{$line++} = $_;
                ($fn_name, $fn_arg) = /&(.*)\((.*)\)/;
                $fn_arg =~ s/\s+//; 
                $initfn{$fn_name} = "$fn_arg" if defined $fn_name;
                next;
        }

        if($section =~/Footer/) {
                $F{$line++} = $_;
                ($fn_name, $fn_arg) = /&(.*)\((.*)\)/;
                $fn_arg =~ s/\s+//; 
                $initfn{$fn_name} = "$fn_arg" if defined $fn_name;
                next;
        }
        next if (/^#/ || /^\s+/);

	if($section =~ /^IV/) {
		($var, $states) = split(/:/);
		@line = split(/#/,$states);
		$i = 0;
		while($index = shift(@line)) {
			$max{"$line:$var"} = $i+1;
			$IV{"$line:$var"}{$i++}= $index;
#			print OUT $IV{$var}{$index},$var,$index,"\n";
		}
		$line++;
		next;
	}

	if($section =~ /^SV/) {
		($var, $states) = split(/:/);
                @line = split(/#/,$states);
                $i = 0;
                while($index = shift(@line)) {
                        $max{"$line:$var"} = $i+1;
                        $SV{"$line:$var"}{$i++}= $index;
#                       print OUT $SV{$var}{$index},$var,$index,"\n";
                }
		$line++;
		next;
	}
	
	if($section =~/State/) {
		($cs,$iv,$ns,$fn) = split(/#/);
		$ST{$cs.":".$iv}= $_;
#		print OUT $ST{$cs.":".$iv}."\n";
		next;
	}
	
	if($section =~/Name/ &! defined($name)) {
		$name = $_;
		next;
	}

	if($section =~/Macro/) {
		($var, $states) = split(/:/);
		$macros{$var} = $states if(defined $states);
#		print "$macros{$var}\n";
		next;
	}
}
close(FSM);

($idx1, $idx2, $idx3, $idx4, $idx5, $idx6) = (sort by_number_reverse keys %IV);
($sdx1, $sdx2, $sdx3, $sdx4, $sdx5) = (sort by_number_reverse keys %SV);

$imax1 = $max{$idx1} ? $max{$idx1} : 1;
$imax2 = $max{$idx2} ? $max{$idx2} : 1;
$imax3 = $max{$idx3} ? $max{$idx3} : 1;
$imax4 = $max{$idx4} ? $max{$idx4} : 1;
$imax5 = $max{$idx5} ? $max{$idx5} : 1;
$imax6 = $max{$idx6} ? $max{$idx6} : 1; 
$smax1 = $max{$sdx1} ? $max{$sdx1} : 1;
$smax2 = $max{$sdx2} ? $max{$sdx2} : 1;
$smax3 = $max{$sdx3} ? $max{$sdx3} : 1;
$smax4 = $max{$sdx4} ? $max{$sdx4} : 1;
$smax5 = $max{$sdx5} ? $max{$sdx5} : 1;

$scount = 0; $icount = 0;
for ($s1=0; $s1<$smax1; $s1++) {
	for ($s2=0; $s2<$smax2; $s2++) {
		for ($s3=0; $s3<$smax3; $s3++) {
    			for ($s4=0; $s4<$smax4; $s4++) {
				for ($s5=0; $s5<$smax5; $s5++) {
	$scount++; $icount=0;
for ($i1=0; $i1<$imax1; $i1++) {
	for ($i2=0; $i2<$imax2; $i2++) {
		for ($i3=0; $i3<$imax3; $i3++) {
			for ($i4=0; $i4<$imax4; $i4++){
				for ($i5=0; $i5<$imax5; $i5++) {
					for ($i6=0; $i6<$imax6; $i6++) {
					$icount++;
					&collate_perl ($scount,$icount,
							$sdx1, $s1,
							$sdx2, $s2,
          						$sdx3, $s3,
							$sdx4, $s4,
							$sdx5, $s5,
							$idx1, $i1,
							$idx2, $i2,
							$idx3, $i3,
							$idx4, $i4,
							$idx5, $i5,
							$idx6, $i6)
					}
				}
			}
		}
	}
}
    }
	}
		}
			}
}
&print_header_perl;
&print_fsm_perl;
&print_footer_perl;
&print_state_variables;
}
print OUT "\n1;\n";
close(OUT);
print LOG "Required helper functions\n";
foreach $key (keys %helper) {
	print LOG "\t$key >> $helper{$key}\n";
}
print LOG "Required init functions\n";
foreach $key (keys %initfn) {
        print LOG "\t$key >> $initfn{$key}\n";
}
close(LOG);
&generate_helper_functions;
&generate_init_functions;
exit;

sub init {
$state_count = 0;
$line = 0;
$find_steady_state = 1;
undef $name;
$section = "Undefined";
undef %IV;
undef %SV;
undef %ST;
undef %max;
undef %F; undef %H;
undef %macros;
undef %fsm;
undef %max;
undef %table_sv;
undef %table_iv;
}

sub print_foot {
	print OUT "\n1;\n";
}

sub collate_perl {
my $i;
my $string ="";
my $next_string = "";
my $val;
my $op;
my $table_iv = "";
my $table_sv = "";
my $var1, $var2;
for ($i = 1; $i<6; $i++ ) {
	$val = $SV{$_[$i*2]}{$_[$i*2+1]}; 
	if ($val =~ /\"/) {
		$op = " eq ";
	} else {
		$op = " == ";
	}
	($var1, $var2) = split(/:/,$_[$i*2]);
        $string .= "$var2".$op.$val
                        ." && " if($val);
	$table_sv .= "$var2".$op.$val 
			.", " if ($val);
  next if (! $val);
	$next_string .="$var2 = $val; ";
}
$next_state{$_[0]} = $next_string;

for ($i = 6; $i<12; $i++ ) {
	$val = $IV{$_[$i*2]}{$_[$i*2+1]};	
	if ($val =~ /\"/) {
		$op = " eq ";
	} elsif ($val =~ /\//) {
		$op = " =~ ";
	} else {
		$op = " == ";
	}
	($var1, $var2) = split(/:/,$_[$i*2]);
	$string .= "$var2".$op.$val
			." && " if($val);
	$table_iv .= "$var2".$op.$val
			.", " if ($val);
}
$string =~ s/ \&\& $//;
$string .= ") {";
$fsm{$_[0].":".$_[1]} = $string;

$table_sv =~ s/ , $//;
$table_iv =~ s/ , $//;
$table_sv{$_[0]} = $table_sv;
$table_iv{$_[1]} = $table_iv;
}

sub print_fsm_perl {
my $i = 0;
my $x = (keys %fsm);
my $f = 0;
my $var;
print OUT "if (";
foreach $key (sort by_number keys %fsm) {
	if($fsm{$key}) {
	if($_ = $ST{$key}) {
		print OUT " elsif (" if ($f);
		print OUT "$fsm{$key}\n";
		($cs,$iv,$ns,$fn)=split(/#/);
		$fn = &replace_macro($fn);
		print OUT "\t# Current State $cs, Indept Var $iv, Next State $ns\n";
		print OUT "\tif (!(\$res = $fn)) {\n";
		print OUT "\t\t$next_state{$ns}\n";
		print OUT "\t\t\$steady_state = 0;\n" if($cs != $ns) &&
				($find_steady_state == 1);
		print OUT "\t} else { &error_handler(\"$n\",\$res,$cs,$ns,$iv); }\n";
		print OUT "}"; $f = 1;
		$_ = $fn;
		($fn_name, $fn_arg) = /^&(.*)\((.*)\)/;
		$fn_arg =~ s/\s+//;
		$helper{$fn_name} = "$fn_arg";
	} 
	}
	$i++;
}

print OUT " else {\n\t&error_handler(\"$n\",\"\",0,0,0);\n}\n";
$helper{"error_handler"} = "\$result,\$current_state,\$next_state,\$indept_var";
}

sub print_head {
print OUT "#Library Files\n";
#print OUT "use $n.pm;\n";
print OUT "use statemachinehelp;\n";
print OUT "use changeorderstates;\n";
print OUT "use database;\n";
print OUT "use filemanip;\n";
}

sub print_header_perl{
my $line;
$n = "anonymous_fsm";
$n = $name if defined($name);
print OUT "#\n";
print OUT "#\n";
print OUT "sub $n {\n";
print OUT "#\n";
print OUT "#This is the Header Section of the Finite State Machine\n";
print OUT "#\n";
foreach $line (sort by_number keys %H) {
	print OUT "$H{$line}\n";
}
print OUT "#\n";
print OUT "my \$res;\n";
if($find_steady_state == 1) {
	print OUT "#Steady State stuff\n";
	print OUT "my \$steady_state = 1;\n";
  print OUT "my \$ss_iteration = 0;\n";
	print OUT "do {\n";
	print OUT "\t\$steady_state = 1;\n";
}
print OUT "#\n";
}

sub print_footer_perl{
my $line;
print OUT "#\n";
if($find_steady_state == 1) {
        print OUT "#Steady State stuff\n";
        print OUT "} while (\$steady_state == 0 && \$ss_iteration++ < 5);\n";
}
print OUT "#\n";
print OUT "#This is the Footer Section of the Finite State Machine\n";
print OUT "#\n";
foreach $line (sort by_number keys %F) {
	print OUT "$F{$line}\n";
} 
print OUT "#\n";
print OUT "} # End of FSM subroutine $name\n";
print OUT "# AAAA June 2003\n";
print OUT "#\n";
}

sub by_number {
	$a <=> $b;
}

sub by_number_reverse {
	$b <=> $a;
}

sub replace_macro {
my $key;
my $fn = $_[0];

foreach $key (keys %macros) {
	return $macros{$key} if($fn =~ /$key/);
}
return $fn;
}

sub generate_helper_functions {
open (HOUT, ">statemachinehelp.pm.protoypes") || die "Can open FSM helper output files";
print HOUT "#\n# State Machines Helper functions file\n#\n";
foreach my $key (keys %helper) {
	my $i = 0;
	print HOUT "sub $key {\n";
	my @args = split(/,/,$helper{$key});
	foreach (@args) {
		print HOUT "\tmy $_ = \$_\[".$i++."];\n";
	}
	print HOUT "\n";
	print HOUT "#\tBody of subroutine goes here .....\n";
	print HOUT "\n";
	print HOUT "return (0);\n";
	print HOUT "} # end of subroutine $key\n";
	print HOUT "#\n#\n#\n";
}
print HOUT "#\n# End of State Machine Helper functions file\n";
print HOUT "# AAAA July 2003\n";
close(HOUT);
}

sub generate_init_functions {
open (HOUT, ">statemachineinit.pm.protoypes") || die "Can open FSM helper output files";
print HOUT "#\n# State Machines Init functions file\n#\n";
foreach my $key (keys %initfn) {
        my $i = 0;
        print HOUT "sub $key {\n";
        my @args = split(/,/,$initfn{$key});
        foreach (@args) {
                print HOUT "\tmy $_ = \$_\[".$i++."];\n";
        }
        print HOUT "\n";
        print HOUT "#\tBody of subroutine goes here .....\n";
        print HOUT "\n";
        print HOUT "return (0);\n";
        print HOUT "} # end of subroutine $key\n";
        print HOUT "#\n#\n#\n";
}
print HOUT "#\n# End of State Machine Init functions file\n";
print HOUT "# AAAA July 2003\n";
close(HOUT);
}

sub print_state_variables {
print LOG "State Variables for Object $name\n";
foreach my $key (sort by_number keys %table_sv) {
	print LOG "\t$key $table_sv{$key}\n";
}
print LOG "\n";
print LOG "Independent Variables for Object $name\n";
foreach my $key (sort by_number keys %table_iv) {
	print LOG "\t$key $table_iv{$key}\n";
}
print LOG "\n";
}
