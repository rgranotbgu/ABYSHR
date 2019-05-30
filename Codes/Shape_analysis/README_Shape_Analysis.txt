
###########################
# Explanation for the Shape Analysis and its files:
###########################

Output2	-> Directory for the output
		
maxima_to_morph.pl -> master script of the analysis. RUN THIS FILE	

Results	-> Directory for processing of the outputs	

filt_maxima.py -> sorts the maxima from ../Maxima/local_maxima.track1. Then, filters the 
maxima according to distance and Ridgelet values - You set the minimal distance between two hills (in “maxima_to_morph.pl”), and the script chose the “strongest” maxima in that range.

sort_maxima.pl - script for manually sorting and filtering the maxima from ../Maxima/local_maxima.track1. very useful when playing with the “maxima.m” user-defined values

plotter_srt.pl -> GMT script for plotting the maxima (hills) - very useful when playing with the “maxima.m” user-defined values (you can see the maxima here, without noise). Also very useful to visually examine the results of the shape analysis.

funct_cross.py -> functions files for the “hill_cross_analysis.py” script.

funct_cross.pyc	-> same as above, but encoded by python.	

project_strike.pl -> script used by “hill_cross_analysis.py” to set the points along the strike of the, from which the cross-section sampling will start.

project_cross.pl -> script used by “hill_cross_analysis.py” to sample the cross-sections (bathymetric profiles).

hill_cross_analysis.py -> The script that samples and analyzes the cross-sections of the hills. Determines the boundaries of the hill (along the cross-section) and computes the shape. 

maxima.srt.fl.track1 -> data file which contains the sorted & filtered maxima.
	
Temp_files - directory with temp files


##*** files that exist only in Example_Roth: 

plot_MAR_28N_-44.8_to_-42.8.pdf -> GMT map of the hills.

plot_MAR_28N_-44.8_to_-42.8.ps -> same as above in ps format.

################### In the Output2 directory: ######################
##*** all these files exist only in Example_Roth: 

many png files -> plots of the cross-sections

MAR_28N_-44.8_to_-42.8_hill_shape.track1.txt -> output of the maxima_to_morph script. it’s recommended to visually examine the results here, to (1) make sure you didn’t sample a hill twice; (2) eliminate hills with bad bathymetry. that escaped the previous procedures.

stat_MAR_28N_-44.8_to_-42.8_hill_shape.track1.txt -> some stats of the hills. Generaly less important.

################### In the Results directory: ######################

shape_data_analysis_1_MOR_side.ipynb - python notebook file for processing the data along a track covering only one side of the mid ocean ridge (see further explanation inside the file).

shape_data_analysis_both_MOR_sides.ipynb - python notebook file for processing the data along a track covering both sides of the mid ocean ridge (see further explanation inside the file).


##*** files that exist only in Example_Roth: 

MAR_28N_-44.8_to_-42.8_hill_shape.track1.txt -> same file as in Output2 (after a visual check of the outputs). Copied here so it will not be accidentally ruined by running maxima_to_morph.pl again.


MAR_28N_-44.8_to_-42.8_shapes_flowline.txt - output file of “shape_data_analysis.ipynb”. contains the shape of the hills along the track.

results_temp.csv - output file of “shape_data_analysis.ipynb”. contains the average shapes for the track + inward percentages.