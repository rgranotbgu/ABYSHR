#!/usr/bin/perl

#********** This plotter-script helps the analysis in two aspects:
#**********     1. Visually checking the results of the 'maxima.m' script (i.e. the locations, azimuths and widths of hills - the products of the ridgelet method).
#**********        For this check - run the script after running 'sort_maxima.pl'.
#**********     2. Visually checking the results of the 'maxima_to_shape.pl' script (i.e. the shape analyis of the hills).

#******* User-defined variables ********
$xmin=-43.9;
$xmax=-43.6;
$ymin=28.1;
$ymax=28.3;
$pre="MAR_28N";
$plotwidth=16; # width of plot (cm)
$strike=5; # length of the strike (km)
$axis_loc="-43.83 28.24"; # location of the axis along the track
#***************************************


$reg="-R$xmin/$xmax/$ymin/$ymax";
$proj="-JM${plotwidth}c";
$ano="-B0.1/0.1 ";
$output="plot_$pre\_$xmin\_to_$xmax";
$misc="-O -K >>";
$scale=$plotwidth/(($xmax-$xmin)*100*cos($ymin*3.14159/180)); #transform plotwidth to km
$mbfile="../Output/$pre\_$xmin\_to_$xmax.multibeam";
$strike=$strike*$scale;


system("grdimage $mbfile.grd $reg $proj -I$mbfile.grad -C../multibeam.cpt  -P -K > $output.ps"); 
system("echo $axis_loc | psxy $proj $reg -Gred -Sc0.2c -W0.01c $misc $output.ps"); # plot the location of the axis along the track
# system("awk '{print \$1,\$2}' ../track1 | psxy $proj $reg -W0.02c $misc $output.ps"); # plot track

#*** plotting hills:
@allfiles=<maxima.srt.fl.track*>; #files of sorted and filtered maxima
$line_wdt="-W0.04c"; #width of the lines that plot the hills
foreach $file (@allfiles){
	system("awk '{print \$1,\$2,\$5,$strike}' $file | psxy $proj $reg -G0 -SV0.005c $line_wdt $misc $output.ps"); #plot hill stirke
	system("awk '{print \$1,\$2,\$5+180,$strike}' $file | psxy $proj $reg -G0 -SV0.005c $line_wdt $misc $output.ps"); #plot hill stirke
	system("awk '{print \$1,\$2,\$5-90,\$3*$scale}' $file | psxy $proj $reg -G0 -SV0.5c+et $line_wdt $misc $output.ps"); #plot hill width
	system("awk '{print \$1,\$2,\$5+90,\$3*$scale}' $file | psxy $proj $reg -G0 -SV0.5c+et $line_wdt $misc $output.ps"); #plot hill width
	system("awk '{print \$1,\$2+0.02,NR}' $file | pstext $proj $reg -F+f7p,Helvetica-Bold,0/0/0+a0+jLM   $misc $output.ps "); #numbering the hills - E-W tracks
	# system("awk '{print \$1+0.02,\$2,NR}' $file | pstext $proj $reg -F+f7p,Helvetica-Bold,0/0/0+a0+jLM   $misc $output.ps "); #numbering the hills - N-S tracks

	## ***** lines 47-55 (the following lines) will only work after running 'maxima_to_shape.pl' *****
	## ***  make sure which direction of progress of the along-strike sampling (which side is cross-section no. '1' and which is no. '60'):
	system("awk '{if (NR%5==0) print \$1,\$2}' Temp_files/temp_prof.txt | psxy $proj $reg -Gred -Sc0.07c $misc $output.ps");
	system("awk '{if (NR%5==0) print \$1,\$2,NR}' Temp_files/temp_prof.txt | pstext $proj $reg -F+f5p,Helvetica-Bold,0/0/0+a0+jLM   $misc $output.ps ");
	
	#*** to see the direction of the cross-hill profiles (which side is left and which is right):
	system("awk '{print \$1,\$2}' Temp_files/tempxy.txt | psxy $proj $reg -Sc0.04c -Gwhite -t30 $misc $output.ps"); #plot all the cross section points
	system("awk 'NR==1{print \$1,\$2}' Temp_files/tempxy.txt | psxy $proj $reg -Gblue -Sc0.07c $misc $output.ps"); #left edge (negative x)
	system("awk 'NR==1{print \$1+0.002,\$2+0.001,\$3*1000}' Temp_files/tempxy.txt | pstext $proj $reg -F+f5p,Helvetica-Bold,0/0/0+a0+jLM   $misc $output.ps "); #left edge (negative x) - text
	system("awk 'END{print \$1,\$2}' Temp_files/tempxy.txt | psxy $proj $reg -Gblue -Sc0.07c $misc $output.ps"); #right edge (positive x)
	system("awk 'END{print \$1+0.001,\$2+0.001,\$3*1000}' Temp_files/tempxy.txt | pstext $proj $reg -F+f5p,Helvetica-Bold,0/0/0+a0+jLM   $misc $output.ps "); #right edge (positive x) - text
}

$yscl=($ymax+$ymin)/2.; #for scale-bar

system("psbasemap $proj $reg $ano -Lx3c/2c+c$yscl+w2k  -F+gwhite --MAP_TICK_PEN_PRIMARY=thin --MAP_SCALE_HEIGHT=3p --FONT_ANNOT=5p -O >>$output.ps");
system ("psconvert $output.ps -Tf -A");
system("open $output.pdf");
