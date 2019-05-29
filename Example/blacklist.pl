#!/usr/bin/perl

open IN, "@ARGV[1]";

$data_file="$ARGV[0]";

$cmd="awk '{if(";
while($line=<IN>){
	@parts=split /\s+/, $line;
	$cmd="$cmd(\$2>$parts[2] && \$2<$parts[3] && \$1>$parts[0] && \$1<$parts[1])||";
}
$cmd1="$cmd(0)){print \$1,\$2,\"99999.00000\"}else{print \$1,\$2,\$3}}' $data_file > $data_file.bl";

system("$cmd1");
	
