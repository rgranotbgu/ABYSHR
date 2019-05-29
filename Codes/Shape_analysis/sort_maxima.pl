#!/usr/bin/perl

# **** This script sort & filter the local.maxima.track files ****

#******* User-defined variables ********
$min_dist=1.5; # minimum spacing between hills [km]
$track_dirct=0; # determines the order of the hills (accroding to lon or lat):
                # 0 for E-W tracks;  1 for NNW-SSE tracks; 2 for NNE-SSW tracks
#***************************************

@raw_maxima_files=<../Maxima/local_maxima.track*>;
foreach $r_file (@raw_maxima_files){
	$end=substr ($r_file, length($r_file)-1, length($r_file));
	if ($track_dirct==0){system("awk '{print \$1,\$2,\$3,\$4,\$5}' $r_file | sort -g -r > maxima.srt.track$end")}  # E-W tracks
	elsif($track_dirct==1){system("awk '{print \$1,\$2,\$3,\$4,\$5}' $r_file | sort -k2 -g > maxima.srt.track$end")}  # NNW-SSE tracks
	elsif($track_dirct==2){system("awk '{print \$1,\$2,\$3,\$4,\$5}' $r_file | sort -k2 -g -r > maxima.srt.track$end")}  #  NNE-SSW tracks
	system("./filt_maxima.py $end $min_dist");
}
