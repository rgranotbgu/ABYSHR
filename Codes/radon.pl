#!/usr/bin/perl

#*** NOTE - on longer tracks, it's more efficient (computing-wise) to break the radon analysis to severel segments - 
#***        that is allowed by the 4 arrays of x&y, and the for-$jk loop ahead

#******* User-defined variables ********
$no_seg=1; # number of different analysis segments
@xlow=(-43.9);
@xhig=(-43.6);
@ylow=(28.1);
@yhig=(28.3);
@orientation=(1);
$region="MAR_28N";
@orientation=(1); # 0 for N-S ; 1 for E-W
$radius=5000; # radius of the Radon transform[m]
$res=150; # resolution of the grid
#***************************************


for($jk=0;$jk<$no_seg;$jk++){
$xmin=$xlow[$jk];
$xmax=$xhig[$jk];
$ymin=$ylow[$jk];
$ymax=$yhig[$jk];
$d2r=3.14159265359/180; #degrees to radians
$earth_r=6371000; #[m]
$rdistlat=$radius/($earth_r*$d2r); #radius in latitude [deg]
$rdistlon=$radius/($earth_r*$d2r*cos($d2r*$ymin)); #radius in longtitude [deg]
$ymin2=$ymin-$rdistlat;
$ymax2=$ymax+$rdistlat;
$xmin2=$xmin-$rdistlon;
$xmax2=$xmax+$rdistlon;
$filename_file="file_list";
$pre="output/$region\_$xmin\_to_$xmax";


##reads mb data and creates grid (unless there is one already)##
$bounds="-R$xmin2/$xmax2/$ymin2/$ymax2";
unless(-e "$pre.multibeam.asc"){
system("mbdatalist -I$filename_file $bounds >datalist.mb");
system("./mbgrid3  -Idatalist.mb -O$pre.multibeam -G1 $bounds -C1/1 -A2 -E$res/$res");  #mbgrid3 create grid using mbgrid, but change the format of output file from only depth values to x-y-z lines format   
}

system("./blacklist.pl $pre.multibeam.asc blacklist.asc");

@datax=();
@datay=();
@dataz=();
open IN, "$pre.multibeam.asc.bl";
$ind1=0; #flag for detecting change in x value - when 0 there is no change, when 1 it has changed
for($i=0;$i<4;++$i){<IN>;}  #skips the first 4 rows
$line=<IN>;
$line=~s/^\s+//;
@parts=split /\s+/, $line;
push @datax, $parts[0];
push @datay, $parts[1];
push @dataz, $parts[2];
$oldx=$parts[0];
$linenum=1;
$numx=1; #counter for the number different x values
while($line=<IN>){
	$line=~s/^\s+//;  #delete whitespace in the beginning of line, if there is one
	@parts=split /\s+/, $line; #split where there is one whitespace (\s) or more (that's what the + stands for)
	unless($ind1){   #unless x value changed
		push @datay, $parts[1];
	}
	if($parts[0]!=$oldx){ #if x value changed
		push @datax, $parts[0];
		$numx++;
		$oldx=$parts[0];
		unless($ind1){
			$ind1=1;
			$numy=$linenum;
		}
	}
	push @dataz, $parts[2];
	$linenum++;
}
close IN;
$numz=@dataz;

open OUT1, ">tempx";
open OUT2, ">tempy";
open OUT3, ">tempz";
for($i=0;$i<$numx;++$i){
	print OUT1 "$datax[$i]\n";
}
for($i=0;$i<$numy;++$i){
	print OUT2 "$datay[$i]\n";
}
for($i=0;$i<$numz;++$i){
	print OUT3 "$dataz[$i]\n";
}
close OUT1;
close OUT2;
close OUT3;


###builds track x & y lists###
for($i=1;$i<=3;$i++){
$track_file="track$i";
@trackx=();
@tracky=();
open IN1, "$track_file";
while($line=<IN1>){
	$line=~s/^\s+//;
	@parts=split /\s+/, $line;
	push @trackx, $parts[0];
	push @tracky, $parts[1];
}
close IN1;



open OUT4, ">tempt";

###builds a new file containing only the track points within range###
$n=0;
for($k=0;$k<@trackx;++$k){
	if(($trackx[$k]>=$xmin)&&
	   ($trackx[$k]<$xmax)&&
	   ($tracky[$k]>=$ymin)&&
	   ($tracky[$k]<$ymax)){
		print OUT4 "$trackx[$k] $tracky[$k]\n";
		$n++;
	}
}

if($n<5){
	print "track$i does not pass through -R$xmin/$xmax/$ymin/$ymax\n";
	close OUT4;
	next;
}

close OUT4;

system("echo \\#define NUMX $numx >radon.h");
system("echo \\#define NUMY $numy >>radon.h");
system("echo \\\#define NUMTRACK $n >>radon.h");
system("echo \\\#define STAT_FILE \\\"$pre.$track_file.stats\\\" >>radon.h");
system("gcc -o radon radon.c -lm");
system("./radon >$pre.$track_file.radon.out");
system("./radon_image.pl $pre $xmin $xmax $ymin $ymax $track_file $orientation[$jk]");
}
}

system("mv temp* Temp_files");