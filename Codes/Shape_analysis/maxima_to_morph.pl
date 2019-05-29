#!/usr/bin/perl

### The master script of the shape analisys ###

#******* User-defined variables ********
$pre="MAR_28N_-43.9_to_-43.6";
$track_dirct=0; # determines the order of the hills (accroding to lon or lat):
                # 0 for E-W tracks;  1 for N-S tracks
$res=150; # resolution of the sampling - set it according to the resolution of the multibeam grid.
$plot=1; # 0 - no plots of cross-sections;  1 - ~10 plots of cross-sections for each hill;  2 - plots all the cross-sections
$s_length=5; #width (1-sided, in km) of the along profile strike. If you want a total width of 10, put 5 here.
$hill_height_trsh_low=80; #minimum height for lower side of hill [meters]
$hill_height_trsh_high=100; #minimum height for higher side of hill [meters]
$min_dist=1.5; #minimum spacing between hills [km]
$min_pro_num=10; #minimum number of succseful cross-sections for a succseful hill
#***************************************

$pro_num=int($s_length*1000/$res*2); #number of cross-sections
# **** sort & filter maxima files ****
@raw_maxima_files=<../Maxima/local_maxima.track*>;
foreach $r_file (@raw_maxima_files){
	$end=substr ($r_file, length($r_file)-1, length($r_file));
	if ($track_dirct==0){system("awk '{print \$1,\$2,\$3,\$4,\$5}' $r_file | sort -g -r > maxima.srt.track$end")}  # E-W tracks
	elsif($track_dirct==1){system("awk '{print \$1,\$2,\$3,\$4,\$5}' $r_file | sort -k2 -g -r > maxima.srt.track$end")}  # N-S tracks
	system("./filt_maxima.py $end $min_dist"); # removes hills spaced less than $min_dist (according to maxima's value)
}


@maxima_files=<maxima.srt.fl.track*>; #sorted and filtered maxima files
foreach $file (@maxima_files){
	$max_val=qx(awk 'BEGIN {max = 0.} {if (\$4>max)max=\$4} END {print max}' maxima.srt.fl.track1);
	open IN, "$file";
	$c=0;
	while($line=<IN>){
		$c+=1;
		print("hill no.$c\n");
		$line=~s/^\s+//;
		($lon,$lat,$m_width,$m_val,$azimuth_s,$dist)=split /\s+/, $line; 
		### azimuth treatment  [positive direction always eastwards] ###
		if ($track_dirct==0){
			## makes sure that the hill profile starts from 3rd & 4th quardants (negative is in the west)
			if (($azimuth_s<=180) && ($azimuth_s>=90)){$azimuth_d=$azimuth_s-90} 
			elsif (($azimuth_s>=0) && ($azimuth_s<90)){$azimuth_d=$azimuth_s+90}
		}
		elsif ($track_dirct==1){
			## makes sure that the hill profile starts from 2nd & 3rd quardants (negative is in the south)
			if (($azimuth_s<=180) && ($azimuth_s>=90)){$azimuth_d=$azimuth_s-90}
			elsif (($azimuth_s>=0) && ($azimuth_s<90)){$azimuth_d=$azimuth_s+270}
		}
		### width treatment (according to the maxima value - values were chosen empirically) ###
		if ($m_val<60){$m_width*=5}
		elsif ($m_val<90){$m_width*=2.5}
		else {$m_width*=2}
		### calls fo the cross-section analysis script:
		system("./hill_cross_analysis.py $pre $end $c $plot $lon $lat $dist $m_width $s_length $azimuth_s $azimuth_d $hill_height_trsh_low $hill_height_trsh_high $res $pro_num $min_pro_num");
	}

}

system("mv temp* Temp_files/"); #
system("mv maxima.srt.track1 Temp_files/"); #
