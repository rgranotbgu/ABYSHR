#!/usr/bin/python

### This script is fully independent - it's runned by maxima_to_shape.pl
### note - the terms "profile" and "cross-section" are interchangeble along the descriptions of the script

import numpy as np
import pylab as plt
import sys
from subprocess import call
from funct_cross import *

# ************************************** Read Data **************************************

pre=sys.argv[1] #name of the grid
track=sys.argv[2] # track no.
num_hill=int(sys.argv[3]) # hill no.
fig=int(sys.argv[4]) # figure option - user defined in maxima_to_morph.pl
lon=float(sys.argv[5])
lat=float(sys.argv[6])
dist=float(sys.argv[7]) # distance along the track
m_width=float(sys.argv[8]) # width of ridgelet maxima
s_length=float(sys.argv[9]) # length of the sampling along the hill strike
azimuth_s=int(float(sys.argv[10])) # azimuth of the strike
azimuth_d=int(float(sys.argv[11])) # azimth perpendicular to the strike
hill_height_trsh_low=float(sys.argv[12]) # user defined in maxima_to_morph.pl
hill_height_trsh_high=float(sys.argv[13]) # user defined in maxima_to_morph.pl
res=int(sys.argv[14]) # resolution of the grid
pro_num=int(sys.argv[15]) # number of sampling points along the strike - calculated in maxima_to_morph.pl
min_pro_num=int(sys.argv[16]) # minimum no. of succsefull profiles for the hill to count - user defined in maxima_to_morph.pl

### projecting points along the strike of the hill - these points are the centers of the cross-sections:
call(["perl","project_strike.pl","{}".format(lon),"{}".format(lat),"{}".format(azimuth_s),"{}".format(s_length),"{}".format(pro_num),"{}".format(pre)])
prof_p=np.loadtxt("temp_prof.txt")[:,0:2] # array of strike points

h_tick=np.arange(1,pro_num+1) #array of the serial number of the cross-sections
h_tick=np.asarray(h_tick,dtype=str)
pr_ar=np.zeros((pro_num,10)) #array of cross-sections' shapes. for averging and std in the end
pr_ar_stat=np.zeros((pro_num,4)) #array of cross-sections' stats. for averging and std in the end
badp=0 #bad profiles counter

plot_diff=int(pro_num/10) # difference between plotted succesful cross-sections (plot option 1 in the master-code)
plot_c=0 # succesful cross-sections counter for plotting 
plot_flag=1 # flag for 1st succesful cross-sections for plotting 

for pn in range(len(prof_p)):
    ### sampling the cross-section:
    call(["perl","project_cross.pl","{}".format(prof_p[pn,0]),"{}".format(prof_p[pn,1]),"{}".format(m_width),"{}".format(azimuth_d),"{}".format(res),"{}".format(pre)])
    xyz=np.loadtxt("tempxyz.txt")
    xfile=np.loadtxt("tempxy.txt")
    x=xfile[:,2]*1000 #km to m
    z=xyz[:,2]

    ### getting rid of NAN values ***
    len1=len(z)
    if pn==0:
        print "max number of points = ",len1
    x=x[z==z]
    z=z[z==z]

    print "{}_{}".format(num_hill,h_tick[pn])  #printing hill number, for user appreciation

    #***** Start of SHAPE algorithm *****
    if len(z)>5 and len(z)>0.6*len1:  # less than 5 sampling-points and there wll be erros (and it will not be a good profile anyway)
                                      # + eliminates profiles with too many (>40%) blank spots (due to NAN values)
        # ************************************** Profile Parameters **************************************
        prof_len=len(z) #length of the profiles (in units of sampling points)
        max_d = min(z) #minimum depth
        min_d = max(z) #maximum depth

        dev=(z[1:len(z)]-z[0:len(z)-1])/(x[1:len(z)]-x[0:len(z)-1]) # calculating slope (1st derivative)
        max_i,conv_width=get_max(dev,len(x)) #locating the central maximum point along the profile - using convolution
        if len(max_i)==1: #if succeeded finding the max point (hill crest)
            mid_i=max_i[0] 
            l_min_p,r_min_p,no_mins=get_mins(z,dev,max_i) #locating the 2 minima along the profile - along the raw bathymetry
            if no_mins==0: #if succeeded locating a minimum in each flank
                real_top=get_top(l_min_p,r_min_p,z) # setting the top of hill as the shallowest point between the 2 minima
                cond_h1 = (z[real_top]-z[l_min_p])>=hill_height_trsh_low and (z[real_top]-z[r_min_p])>=hill_height_trsh_high #condition for minimum height (1)
                cond_h2 = (z[real_top]-z[r_min_p])>=hill_height_trsh_low and (z[real_top]-z[l_min_p])>=hill_height_trsh_high #condition for minimum height (2)
                ### checks: 1) that max and mins are not the same point; 2) that mins are lower than max; 3) that the profile has a user-defined double-minimum height
                if abs(l_min_p-mid_i)>1 and abs(r_min_p-mid_i)>1 and (z[l_min_p]<z[mid_i]) and (z[r_min_p]<z[mid_i]) and (cond_h1 or cond_h2): 
                    ### calculate the shape of the hill along the cross-section:
                    l_width,r_width,l_height,r_height,minmax_slope_l,minmax_slope_r,max_slope_l,max_slope_r,l_real_area,r_real_area=get_shapes(x,z,dev,res,real_top,l_min_p,r_min_p)

    	            #***plotting hill profile***
                    if plot_flag==1:
                        plot_c=plot_diff
                        plot_flag=0
                    else:
                        plot_c+=1

                    if fig==1: # plot every *plot_diff* profiles
                        if plot_c%plot_diff==0:
                            xlimit=x[len(x)-1]*2-x[len(x)-2]
                            # scaled
                            yscl=2.
                            xscl=(x[len(x)-1]-x[0])/(max(z)-min(z))*yscl
                            while xscl>=327.68:  # this is the limit of pylab for savefig
                                yscl*=0.9
                                xscl=(x[len(x)-1]-x[0])/(max(z)-min(z))*yscl
                            plt.figure(figsize=(xscl,yscl))
                            plt.plot(x,z)
                            plt.scatter(x,z)
                            plt.plot(x[mid_i],z[mid_i],"o",c='orange',markersize=9,label="Conv max")
                            plt.plot(x[real_top],z[real_top],"o",c='r',markersize=9,label="Real max")
                            plt.plot([x[l_min_p],x[r_min_p]],[z[l_min_p],z[r_min_p]],"o",c='g',markersize=9,label="Min")
                            plt.xlim(-xlimit,xlimit)
                            plt.ylim(min(z)-50,max(z)+50)
                            plt.legend(numpoints=1,loc=0)
                            if num_hill<10:
                                plt.savefig('Output2/{0}_track{1}_hill_0{2}_{3}.png'.format(pre,track,num_hill,h_tick[pn]))
                            else:
                                plt.savefig('Output2/{0}_track{1}_hill_{2}_{3}.png'.format(pre,track,num_hill,h_tick[pn]))
                    elif fig==2:
                            xlimit=x[len(x)-1]*2-x[len(x)-2]

                            # scaled
                            yscl=2.
                            xscl=(x[len(x)-1]-x[0])/(max(z)-min(z))*yscl
                            while xscl>=327.68:  # this is the limit of pylab for savefig
                                yscl*=0.9
                                xscl=(x[len(x)-1]-x[0])/(max(z)-min(z))*yscl


                            plt.figure(figsize=(xscl,yscl))
                            plt.plot(x,z)
                            plt.scatter(x,z)
                            plt.plot(x[mid_i],z[mid_i],"o",c='orange',markersize=9,label="Conv max")
                            plt.plot(x[real_top],z[real_top],"o",c='r',markersize=9,label="Real max")
                            plt.plot([x[l_min_p],x[r_min_p]],[z[l_min_p],z[r_min_p]],"o",c='g',markersize=9,label="Min")
                            plt.xlim(-xlimit,xlimit)
                            plt.ylim(min(z)-50,max(z)+50)
                            plt.legend(numpoints=1,loc=0)



                            if num_hill<10:
                                plt.savefig('Output2/{0}_track{1}_hill_0{2}_{3}.png'.format(pre,track,num_hill,h_tick[pn]))
                            else:
                                plt.savefig('Output2/{0}_track{1}_hill_{2}_{3}.png'.format(pre,track,num_hill,h_tick[pn]))

                else: # else for | abs(l_min_p-mid_i)>1 and abs(r_min_p-mid_i)>1 and (z[l_min_p]<z[mid_i]) and (z[r_min_p]<z[mid_i]) and (cond_h1 or cond_h2) |
                    prof_len=min_d=max_d=conv_width=l_width=r_width=l_height=r_height=minmax_slope_l=minmax_slope_r=max_slope_l=max_slope_r=l_real_area=r_real_area=0
                    badp+=1

            else: # else for | no_mins==0 |
                prof_len=min_d=max_d=conv_width=l_width=r_width=l_height=r_height=minmax_slope_l=minmax_slope_r=max_slope_l=max_slope_r=l_real_area=r_real_area=0
                badp+=1

        else: # else for | len(max_i)==1 |
            prof_len=min_d=max_d=conv_width=l_width=r_width=l_height=r_height=minmax_slope_l=minmax_slope_r=max_slope_l=max_slope_r=l_real_area=r_real_area=0
            badp+=1
        
        pr_ar[pn]=np.array([l_width,r_width,l_height,r_height,minmax_slope_l,minmax_slope_r,max_slope_l,max_slope_r,l_real_area,r_real_area])
        pr_ar_stat[pn]=np.array([prof_len,min_d,max_d,conv_width])
    else: # else for | len(z)>5 and len(z)>0.6*len1 |
        prof_len=min_d=max_d=conv_width=l_width=r_width=l_height=r_height=minmax_slope_l=minmax_slope_r=max_slope_l=max_slope_r=l_real_area=r_real_area=0
        badp+=1
    
    if num_hill==1 and pn==0: #if for making titles of columns
        with open('Output2/{0}_hill_shape.track{1}.txt'.format(pre,track), 'w') as fh:
            fh.write('no.      longtitude  latitude   distance  l-width  r-width  l-height  r-height  l-minmax-slope  r-minmax-slope  l-max-slope  r-max-slope  l-area  r-area\n')
        with open('Output2/{0}_hill_shape.track{1}.txt'.format(pre,track), 'a') as fh:
            fh.write('{0:3}_{1:4}{2:11.5f}{3:10.5f}{4:10.3f}{5:8.0f}{6:10.0f}{7:9.0f}{8:10.0f}{9:12.1f}{10:16.1f}{11:15.1f}{12:14.1f}{13:12.4f}{14:11.4f}\n'
                .format(num_hill,h_tick[pn],lon,lat,dist,l_width,r_width,l_height,r_height,minmax_slope_l,minmax_slope_r,max_slope_l,max_slope_r,l_real_area,r_real_area))

        with open('Output2/stat_{0}_hill_shape.track{1}.txt'.format(pre,track), 'w') as fh:
            fh.write('no.      longtitude  latitude    distance  profile-len  min-depth  max-depth  conv\n')
        with open('Output2/stat_{0}_hill_shape.track{1}.txt'.format(pre,track), 'a') as fh:
            fh.write('{0:3}_{1:4}{2:11.5f}{3:10.5f}{4:12.3f}{5:8.0f}{6:14.0f}{7:11.0f}{8:7.0f}\n'.format(num_hill,h_tick[pn],lon,lat,dist,prof_len,min_d,max_d,conv_width))

    else:
        with open('Output2/{0}_hill_shape.track{1}.txt'.format(pre,track), 'a') as fh:
            fh.write('{0:3}_{1:4}{2:11.5f}{3:10.5f}{4:10.3f}{5:8.0f}{6:10.0f}{7:9.0f}{8:10.0f}{9:12.1f}{10:16.1f}{11:15.1f}{12:14.1f}{13:12.4f}{14:11.4f}\n'
                .format(num_hill,h_tick[pn],lon,lat,dist,l_width,r_width,l_height,r_height,minmax_slope_l,minmax_slope_r,max_slope_l,max_slope_r,l_real_area,r_real_area))

        with open('Output2/stat_{0}_hill_shape.track{1}.txt'.format(pre,track), 'a') as fh:
            fh.write('{0:3}_{1:4}{2:11.5f}{3:10.5f}{4:12.3f}{5:8.0f}{6:14.0f}{7:11.0f}{8:7.0f}\n'.format(num_hill,h_tick[pn],lon,lat,dist,prof_len,min_d,max_d,conv_width))

# ************************************** Averaging Profiles ************************************
### start with worst case scenario - if less than the minimum no. of profiles are good, than the avg. and std are set to 0.
prof_len=min_d=max_d=conv_width=l_width=r_width=l_height=r_height=minmax_slope_l=minmax_slope_r=max_slope_l=max_slope_r=0 #if all profiles are bad
l_area=r_area=l_real_area=r_real_area=0 #if all profiles are bad
prof_len_std=min_d_std=max_d_std=conv_width_std=l_width_std=r_width_std=l_height_std=r_height_std=minmax_slope_l_std=0
minmax_slope_r_std=max_slope_l_std=max_slope_r_std=l_real_area_std=r_real_area_std=0 

if badp<=(pro_num-min_pro_num):
    (l_width,r_width,l_height,r_height,minmax_slope_l,minmax_slope_r,max_slope_l,max_slope_r,l_real_area,r_real_area)=pr_ar.sum(0)/(pro_num-badp)
    (prof_len,min_d,max_d,conv_width)=pr_ar_stat.sum(0)/(pro_num-badp)
    if badp<=(pro_num-min_pro_num):
        pr_ar=pr_ar[pr_ar!=0].reshape(pro_num-badp,10)
        l_width_std=np.std(pr_ar[:,0])
        r_width_std=np.std(pr_ar[:,1])
        l_height_std=np.std(pr_ar[:,2])
        r_height_std=np.std(pr_ar[:,3])
        minmax_slope_l_std=np.std(pr_ar[:,4])
        minmax_slope_r_std=np.std(pr_ar[:,5])
        max_slope_l_std=np.std(pr_ar[:,6])
        max_slope_r_std=np.std(pr_ar[:,7])
        l_real_area_std=np.std(pr_ar[:,8])
        r_real_area_std=np.std(pr_ar[:,9])

        pr_ar_stat=pr_ar_stat[pr_ar_stat!=0].reshape(pro_num-badp,4)
        min_d_std=np.std(pr_ar_stat[:,1])
        max_d_std=np.std(pr_ar_stat[:,2])
        conv_width_std=np.std(pr_ar_stat[:,3])
        

with open('Output2/{0}_hill_shape.track{1}.txt'.format(pre,track), 'a') as fh:
        fh.write('avg_{0:3}{1:12.5f}{2:10.5f}{3:10.3f}{4:8.0f}{5:10.0f}{6:9.0f}{7:10.0f}{8:12.1f}{9:16.1f}{10:15.1f}{11:14.1f}{12:12.4f}{13:11.4f}\n'
            .format(num_hill,lon,lat,dist,l_width,r_width,l_height,r_height,minmax_slope_l,minmax_slope_r,max_slope_l,max_slope_r,l_real_area,r_real_area))
        fh.write('std_{0:3}{1:12.5f}{2:10.5f}{3:10.3f}{4:8.0f}{5:10.0f}{6:9.0f}{7:10.0f}{8:12.1f}{9:16.1f}{10:15.1f}{11:14.1f}{12:12.4f}{13:11.4f}\n'
            .format(num_hill,lon,lat,dist,l_width_std,r_width_std,l_height_std,r_height_std,minmax_slope_l_std,minmax_slope_r_std,max_slope_l_std,max_slope_r_std,l_real_area_std,
                r_real_area_std))

with open('Output2/stat_{0}_hill_shape.track{1}.txt'.format(pre,track), 'a') as fh:
        fh.write('avg_{0:3}{1:12.5f}{2:10.5f}{3:12.3f}{4:8.0f}{5:14.0f}{6:11.0f}{7:7.0f}\n'.format(num_hill,lon,lat,dist,prof_len,min_d,max_d,conv_width))
        fh.write('std_{0:3}{1:12.5f}{2:10.5f}{3:12.3f}{4:8.0f}{5:14.0f}{6:11.0f}{7:7.0f}\n'.format(num_hill,lon,lat,dist,prof_len,min_d_std,max_d_std,conv_width_std))