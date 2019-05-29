#!/usr/bin/perl

#******* User-defined variables ********
$xmin=-43.9;
$xmax=-43.6;
$ymin=28.1;
$ymax=28.3;
$pre="MAR_28N";
$strike=5; # length of the strike (km)
$plotwidth=18; # width of plot (cm)
#***************************************

$reg="-R$xmin/$xmax/$ymin/$ymax";
$proj="-JM${plotwidth}c";
$ano="-B0.2g0.2";
$output="plot";
$scale=$plotwidth/(($xmax-$xmin)*100*cos($ymin*3.14159/180)); #transform plotwidth to km
$strike=$strike*$scale;
$misc="-O -K >>";


@allfiles=<local_maxima.track*>;
$mbfile="../Output/$pre\_$xmin\_to_$xmax.multibeam";
system("gmt grdimage $mbfile.grd $reg $proj -I$mbfile.grad -C../multibeam.cpt -K -P > $output.ps"); 
foreach $file (@allfiles){
	system("awk '{print \$1,\$2,\$5,$strike}' $file | gmt psxy $proj $reg -G0 -SV0.005c $misc $output.ps"); #plot hill stirke
	system("awk '{print \$1,\$2,\$5+180,$strike}' $file | gmt psxy $proj $reg -G0 -SV0.005c $misc $output.ps"); #plot hill stirke
	system("awk '{print \$1,\$2,\$5-90,\$3*$scale}' $file | gmt psxy $proj $reg -G0 -SV0.1c+et $misc $output.ps"); #plot hill width
	system("awk '{print \$1,\$2,\$5+90,\$3*$scale}' $file | gmt psxy $proj $reg -G0 -SV0.1c+et $misc $output.ps"); #plot hill width
}

system("gmt psbasemap $proj $reg $ano -O >>$output.ps");
system ("gmt psconvert $output.ps -Tf -A");
system("open $output.pdf");