#!usr/local/perl

package myLibconfig;

use Data::Dumper;

use warnings;
use strict;

sub new
{
	my ($filename) = $_[1];
	open(FH,$filename);
	my @lineArr = <FH>;
	my $state = 0;	# not in comment
	my @resultArr;
	foreach my $line (@lineArr){
		my $cindex = index( $line , "/*" );
		my $ccloseindex = index( $line , "*/" );
		if($state == 0){
			if($cindex > -1){
				$state = 1;
			}
			if($cindex > 0){
				push @resultArr,substr($line,0,$cindex)."\n";
			}			
			if($cindex == -1 && $ccloseindex == -1){
				push @resultArr,$line;
			}
		}
		else{ # in comment			
			if($ccloseindex >= 0){
				$state = 0;
				if($ccloseindex+2 < length($line)){
					push @resultArr,substr($line,$ccloseindex+2,length($line))."\n";
				}
			}
		}
		
	}
	foreach my $rline (@resultArr){
		my $index1 = index($rline,"#");
		my $index2 = index($rline,"//");
		if($index1 == 0 || $index2 == 0){$rline = "";};
		if($index1 > 0){
			$rline = substr($rline,0,$index1);			
		}
		if($index2 > 0){
			$rline = substr($rline,0,$index2);
		}
	}
	close FH;
	my %hash = ();
	my %result = ();
	my @_arr = (1,2);


	my $parentNode = "";
	my @stateArr = ("json");

	my $arrIndex = 0;
	my $tmpkey = $resultArr[0];
	foreach my $line(@resultArr){
		my $ll = trim($line);
		if($ll ne ""){
			if(index($ll,':') > 0 && index($ll,'=') == -1){
				my $v = length($parentNode)-1;
				if($v > -1 && rindex($parentNode,".") != length($parentNode)-1){
					$parentNode .= ".";
				}
				$parentNode .= substr($ll,0,index($ll,':'));
			}	
			elsif(index($ll,'{') > -1){
				if($stateArr[0] eq "array"){
					$parentNode .= $arrIndex."]";
				}
				unshift(@stateArr,"json");
				$parentNode .= ".";
			}			
			if(index($ll,"}") == 0){
				shift(@stateArr);
				if($stateArr[0] eq "array"){
					my $leftindex = rindex($parentNode,"[");
					$parentNode = substr($parentNode,0,$leftindex+1);
				}
				else{
					my @arr = split(/\./,$parentNode);				
					pop(@arr);
					$parentNode = join(".",@arr);
					if($parentNode ne ""){
						$parentNode .= ".";
					}
				}
			}
			if(index($ll,',') > -1 && index($ll,"=") == -1){
				if($stateArr[0] eq "array"){
					$arrIndex ++;	
				}
			}
			elsif(index($ll,"=") == length($ll)-1){
				my $str = substr($ll,0,length($ll) -1 );
				$str = trim($str);
				if(rindex($parentNode,".") ne (length($parentNode)-1)){
					$parentNode .= ".";
				}
				$parentNode .= $str;
			}
			elsif(index($ll,"(") == 0){
				
				unshift(@stateArr,"array");
				$parentNode .= "[";
			}
			elsif(index($ll,")") == 0){
				
				shift(@stateArr);
				$arrIndex = 0;
				my @arr = split(/\./,$parentNode);
				pop(@arr);
				$parentNode = join(".",@arr);
			}
			elsif(index($ll,"=") > 0 && index($ll,"=") < length($ll)-1){
				my @arr = split('=',$ll);
				my $key = trim($arr[0]);
				my $val = trim($arr[1]);
				$result{$parentNode.$key} = $val;

				my @keys = split(/\./,$parentNode.$key);
				my $lt = scalar(@keys);
				my $exp = "\$hash";
				for(my $i = 0; $i < $lt;$i++){
					$exp .= "{\$keys[$i]}";
				}
				$exp .= " = \$val;";
				eval($exp);				
			}		
		}
	}

	my %output = ();

	my %countHash = ();
	foreach my $key(keys %result){
		my $index = rindex($key,"[");
		my $newkey = substr($key,0,$index);
		if($index > -1){
			my $num = substr($key,$index+1,1);
#			print $num,$newkey;
			if(defined($countHash{$newkey}) && $countHash{$newkey} > $num){
			}
			else{
				$countHash{$newkey} = $num;
			}	
		}
	}

	foreach my $key(keys %countHash){
		my @nameArr = split(/\./,$key);
		my $arrID = join('_',@nameArr);
		my $testexp = "my \@$arrID = ();\n";
		my $hashexp = "\$hash";
		for(my $i = 0; $i < scalar(@nameArr)-1; $i++){
			$hashexp .= "{'".$nameArr[$i]."'}";
		}
		$hashexp .= "{'".$nameArr[scalar(@nameArr)-1]."[";
		for(my $i = 0; $i < $countHash{$key}+1; $i++ ){
			$testexp .= "push(\@$arrID,$hashexp"."$i]'});\n";
		}
		my $outputexp = "\$output";
		for(my $i = 0; $i < scalar(@nameArr); $i++){
			$outputexp .= "{'".$nameArr[$i]."'}";
		}
	
	$testexp .= $outputexp." = \\\@$arrID;";
		eval($testexp);
	}

	print Dumper(\%output);
}

sub trim
{
	my $str = shift;
	$str =~ s/^\s+//;
	$str =~ s/\s+$//;
	return $str;
}

1;
