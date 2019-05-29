
###########################
# Explanation for the Radon calculation and its files:
###########################

blacklist.asc --> This is a text file, each line of which defines
a region in the multibeam data in a similar way to the -R option in
gmt, except that there is no -R and no slashes. for example
"-R-160/-159/-30/-29" becomes "-160 -159 -30 -20".  These regions
define places where the multibeam data are "blacklisted" and  not used
in the radon transform calculation.  This is useful if there is a
large seamount or plateau present and you don’t want to analyse the
portion of the track that crosses the anomalous feature.  Generally
you will start with this file empty and then add lines iteratively
until the radon transform output looks ok.  Generally this will not be
needed too much, but this file must be present (Even if it is empty)
or the radon.pl script will crash.

blacklist.pl --> perl script that searches through the gridded
multibeam data and replaces the bathy values in the blacklisted
regions with the invalid value (999999.00000).  This is called by the
script radon.pl script.

MB_files --> data directory containing the multibeam data files.  This
can be located anywhere on your system and can be read-only.

file_list --> this is a text file that contains either the relative or
absolute paths to the data you wish to analyse. Note that input files need to be in *.mbxxx format (not fbt files)

mbgrid3 --> Multibeam gridding routine.

multibeam.cpt --> multibeam color palette file.  You will probably
need to modify this to give good images in your region of interest.

Output --> directory containing the output and image files of the
gridded multibeam and radon transform data

radon.c --> c-code that does the Radon transform of the multibeam data
and calculates some other data statistics.

radon.cpt --> colorpalette file for the radon transform data.  This
may also need to be modified.

radon.pl --> master script. This calls all the other routines needed
and to perform the Radon transform of the data in "file_list" you will
need to type"./radon.pl"

radon_image.pl --> plotting script.  This script makes the GMT plots
of the data and Radon transformed data.

track* --> these files are latitude and longitude coordinates of the
shiptrack used as the "origin" or calculation point of the Radon
integrals.  What this means is that the Radon transform of the data is
a series of line integrals that run through this point and have
varying azimuths.  These don't have to correspond to the actual
shiptrack, it is just that the shiptrack generally provides a
convenient origin for the Radon transform routine, because it runs
down the center of a multibeam swath.  Generally, I prefer to split
the shiptrack into pieces where there is a sharp turn etc to avoid a
bias towards data near the inside corner of the turn. 
This feature also provides the opportunity to use different shiptracks 
(or custom ones) across a single dataset.  A use for this might be if
you have continuous data coverage, you might want to create some synthetic
shiptracks that are orthogonal to the general trend of the abyssal-hill fabric 
in a region. This makes it easier to visually interpret the output of the
Radon transform routine.

Temp_files - directory with temp files


You will also need to modify the radon.pl script a bit.  The most
important place is near the beginning of the file:

@xlow=(-43.9);
@xhig=(-43.6);
@ylow=(28.1);
@yhig=(28.3);
@orientation=(1);

These arrays define the regions used to split up a survey into
manageable chunks to preserve memory, reduce computation time and
allow for easy interpretation of results.  The first array is the
lower Longitude bound on the region over which we are doing the
analysis, the second is the upper longitude bound, the third the lower
Latitude bound and the fourth is the upper Latitude bound.  The last
array determines the final orientation for the radon plot outputted by
the radon_image.pl script.  
Don't worry about edge effects for the radon transform of the data.  The code
automatically allows a generous pad around the specified region to
ensure that the radon transform is not biased.  This means that
although the plots and output are restricted to this specific region,
the transform routine loads in enough extra data to ensure that the
line integrals near the edge of the region have access to the recorded
data outside the region.  You can see this because the radon transform
output will appear seamless if you plot the output from various
regions on one large plot.

The bounds on the for loop can be changed to run the routine over an
entire dataset.  When I was using this code I would run it on a single
survey at a time overnight and then come in the next day to look at
individual chunks and see if it needed to be rerun on any of them.

** Also please note that if you want to regrid the data for some reason,
that you have to delete the Output/*.asc file first.  radon.pl looks
for this file and if it exists, it skips the gridding to save time.
This is usually not a step that will need to be repeated if you want
to blacklist a region and rerun the radon transform.

Alright the output that is important will end up in the “Output"
directory and should look like (only in the Example_Roth directory):

Output/MAR_28N_-43.9_to_-43.6.multibeam.asc
Output/MAR_28N_-43.9_to_-43.6.multibeam.asc.bl
Output/MAR_28N_-43.9_to_-43.6.multibeam.asci
Output/MAR_28N_-43.9_to_-43.6.multibeam.grad
Output/MAR_28N_-43.9_to_-43.6.multibeam.grd
Output/MAR_28N_-43.9_to_-43.6.multibeam.mb-1
Output/MAR_28N_-43.9_to_-43.6.track1.multibeam.bl.eps
Output/MAR_28N_-43.9_to_-43.6.track1.multibeam.bl.ps
Output/MAR_28N_-43.9_to_-43.6.track1.multibeam.eps
Output/MAR_28N_-43.9_to_-43.6.track1.multibeam.ps
Output/MAR_28N_-43.9_to_-43.6.track1.radon.bl.eps
Output/MAR_28N_-43.9_to_-43.6.track1.radon.bl.ps
Output/MAR_28N_-43.9_to_-43.6.track1.radon.eps
Output/MAR_28N_-43.9_to_-43.6.track1.radon.grad
Output/MAR_28N_-43.9_to_-43.6.track1.radon.grd
Output/MAR_28N_-43.9_to_-43.6.track1.radon.out
Output/MAR_28N_-43.9_to_-43.6.track1.radon.out.bl
Output/MAR_28N_-43.9_to_-43.6.track1.radon.ps
Output/MAR_28N_-43.9_to_-43.6.track1.stats

Here is a brief description of these files:

MAR_28N_-43.9_to_-43.6.multibeam.asc --> gridded multibeam data used
for Radon transform

MAR_28N_-43.9_to_-43.6.multibeam.asc.bl --> same as above, but after
the regions to blacklist have been removed

MAR_28N_-43.9_to_-43.6.multibeam.asci --> same as the first file but
with NaN in place of invalid value.  This is used to make prettier
plots in GMT.

MAR_28N_-43.9_to_-43.6.multibeam.grad --> false illumination of the
multibeam *.grd file

MAR_28N_-43.9_to_-43.6.multibeam.grd --> gridded multibeam data in
grd format used for plotting and later for sampling bathymetric profiles.

MAR_28N_-43.9_to_-43.6.multibeam.mb-1 --> superfluous file generated by mbgrid

MAR_28N_-43.9_to_-43.6.track1.multibeam.ps --> image of the multibeam data

MAR_28N_-43.9_to_-43.6.track1.multibeam.eps --> same as last but in eps format

MAR_28N_-43.9_to_-43.6.track1.multibeam.bl.ps --> image of the blacklisted multibeam data

MAR_28N_-43.9_to_-43.6.track1.multibeam.bl.eps --> same as last but in eps format

MAR_28N_-43.9_to_-43.6.track1.radon.ps --> image of the radon
transform output in postscript

MAR_28N_-43.9_to_-43.6.track1.radon.eps --> eps image of radon transform output

MAR_28N_-43.9_to_-43.6.track1.radon.bl.eps --> ps image of blacklisted radon transform output

MAR_28N_-43.9_to_-43.6.track1.radon.bl.eps --> same as last but in eps format


MAR_28N_-43.9_to_-43.6.track1.radon.grad --> false illumination for
the radon output

MAR_28N_-43.9_to_-43.6.track1.radon.grd --> grd format file of the
radon transform output.  Used only for plotting.

MAR_28N_-43.9_to_-43.6.track1.radon.out --> the Radon transform
output.  The format of this file is ascii columns with the columns
representing, in order: Azimuth (degrees), Latitude, Radon transform,
Longitude.  The latitude and longitude values in this file are those
taken from track1 and lying in the region of interest.


MAR_28N_-43.9_to_-43.6.track1.stats --> Some statistics about the
average and rms values of the bathymetry in regions of vaying size
around the trackpoints.


###########################
# Explanation for the Wavelet calculation and its files:
###########################

In the “Maxima” directory:

maxima.m --> the script that calculates the Wavelet transform of the Radon data. Thus,
It produces the locations, direction & estimated widths of the hills (named as “maxima”).
The "maxima.m" script has several features that help to filter the ridges to remove noisy results. In some datasets there has been no ping editing, so spurious beams can
give a lot of false positives.  These need to be filtered out.  This
procedure is required in general for noisy data, so proper editing of
the bathymetry files can make a big difference.  Anyway these
parameters are listed here:

azimin=2;
azimax=30;
These two parameters limit the orientation over which the wavelet transform is calculated.  You can open this wide up to azimin=2 and azimax=179, but generally we have a good idea what the azimuth of the abyssal hills in a region are so we can a priori restrict the program to search over a restricted azimuth range.

filtscale=0.8;
filtsize=4;
A gaussian denoising filter is applied to the data to remove some false positives that result from noise.  Increasing filtscale makes this filter stronger.  You should also increase filtsize if you make filtscale greater than 1.0

threshold=5;
Decreasing the threshold will cause more maxima to be retained, Increasing it rejects the smaller (in magnitude, see above) abyssal ridges

scale_min=0.5;
scale_max=1.7;
nscales=200;
This defines the number of wavelet scales that are used to analyse the data.  With these settings it will search for abyssal ridges whose width (across their long axis) is between 500m and 1.7km.  Decreasing nscales makes a coarser search which can help reduce the number of ridges detected at a single location.

Basically you need to play with these parameters for each dataset
analysed and even modify them across a survey area if the survey area
is large.

A second set of paramters describe how the data are handled:

quads=load('../blacklist.asc’);
This uses the blacklist coordinatres to reject abyssal ridges found in a particular region, as described in the the Radon transform routines (above).

orient=[4];
This parameter decides which axis is used to plot the data.  If the track runs N-S use orient=2, if E-W use orient=4.  This is an array so there is one orientation parameter per shiptrack (it track1, track2, track3, etc.)

track=[1];
This is the array of track numbers.  Here we only are looking at track1.

More files here 

find_maxima.m —> function file for maxima.m

get_dist.m —> function file for maxima.m 

wtrans.m —> function file for maxima.m

infiles.track1 -> contains the radon output files from Output directory.

local_maxima.track1 - The output of “maxima.m”. The the columns in the file are,
in order: Longitude, Latitude, Width (km), Ridgelet value, Azimuth (degrees).

plotter_maxima.pl -> GMT script for plotting the results of “maxima.m”.

plot.ps -> GMT map with maxima (hills) detected by “maxima.m”.

plot.pdf -> same as above but as pdf file
