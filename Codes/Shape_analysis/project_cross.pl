#!/usr/bin/perl

$x=$ARGV[0];
$y=$ARGV[1];
$length=$ARGV[2];
$azimuth=$ARGV[3];
$spacing=$ARGV[4]/1000;
$pre=<../Output/$ARGV[5]>;

$width=0.0444;

system ("gmt project $pre.multibeam.grd -C$x/$y  -A$azimuth -G$spacing -Q -W-$width/$width -L-$length/$length > tempxy.txt");
system ("awk '{print \$1,\$2}' tempxy.txt | gmt grdtrack -G$pre.multibeam.grd -N  > tempxyz.txt");
