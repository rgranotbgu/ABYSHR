#!/usr/bin/perl

#******* User-defined variables ********
$xmin=-44.8;
$xmax=-42.8;
$ymin=27.6;
$ymax=28.9;
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
system("grdimage $mbfile.grd $reg $proj -I$mbfile.grad -C../multibeam.cpt -K -P > $output.ps"); 
foreach $file (@allfiles){
	system("awk '{print \$1,\$2,\$5,$strike}' $file | psxy $proj $reg -G0 -SV0.005c $misc $output.ps"); #plot hill stirke
	system("awk '{print \$1,\$2,\$5+180,$strike}' $file | psxy $proj $reg -G0 -SV0.005c $misc $output.ps"); #plot hill stirke
	system("awk '{print \$1,\$2,\$5-90,\$3*$scale}' $file | psxy $proj $reg -G0 -SV0.1c+et $misc $output.ps"); #plot hill width
	system("awk '{print \$1,\$2,\$5+90,\$3*$scale}' $file | psxy $proj $reg -G0 -SV0.1c+et $misc $output.ps"); #plot hill width
}

system("psbasemap $proj $reg $ano -O >>$output.ps");
system ("psconvert $output.ps -Tf -A");
system("open $output.pdf");