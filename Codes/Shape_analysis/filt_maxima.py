#!/usr/bin/python

import numpy as np
import sys

tr=sys.argv[1]
min_dist=float(sys.argv[2])

def lonlatdist(p1,p2):
    R=6371.
    p1=np.deg2rad(p1)
    p2=np.deg2rad(p2)
    a=(np.sin((p1[1]-p2[1])/2))**2+np.cos(p1[1])*np.cos(p2[1])*(np.sin((p1[0]-p2[0])/2))**2
    c=2*np.arctan2(np.sqrt(a),np.sqrt(1-a))
    d=R*c
    return d

data=np.loadtxt('maxima.srt.track{}'.format(tr))
if data.ndim>1:
    data_filt=[]
    i=0
    while i<len(data)-1:
        if lonlatdist(data[i,0:2],data[i+1,0:2])>min_dist:
            data_filt.append(list(data[i]))
            i+=1
            if i==len(data)-1 and lonlatdist(data[i,0:2],data[i-1,0:2]):
                data_filt.append(list(data[i]))
        else:
            j=i
            largest=list(data[j])
            while lonlatdist(data[j,0:2],data[j+1,0:2])<=min_dist and j<len(data)-2:
                if data[j+1,3]>data[j,3]:
                    largest=list(data[j+1])
                # print largest
                j+=1
            data_filt.append(largest)
            i=j+1



    #*** adds distance along track (starts from the 1st hill) ***
    dist=0.
    data_filt[0].append(dist)
    for i2 in range(1,len(data_filt)):
        dist+=lonlatdist(data_filt[i2][0:2],data_filt[i2-1][0:2])
        data_filt[i2].append(dist)

else:
    data_filt=np.hstack((data.reshape(1,5),np.array(0.).reshape(1,1)))


np.savetxt('maxima.srt.fl.track{}'.format(tr),data_filt,fmt='%1.7e' ,delimiter='   ')

