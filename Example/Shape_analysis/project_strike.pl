#!/usr/bin/perl

$width=0.0444;

$d2r=3.14159265359/180; #degrees to radians

$x=$ARGV[0];
$y=$ARGV[1];
$azimuth=$ARGV[2];
$length=$ARGV[3];  
$pro_num=$ARGV[4];
$pre=<../Output/$ARGV[5]>;
$spacing=$length/($pro_num*0.5-0.5);

system ("gmt project $pre.multibeam.grd -C$x/$y -A$azimuth -G$spacing -Q -L-$length/$length > temp_prof.txt"); 
