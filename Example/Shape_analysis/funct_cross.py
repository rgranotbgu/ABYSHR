import numpy as np

def get_max(dzdx,len_x):
    '''Locates the single central maximum point along the profile, using a growing 1-D convultion vector.
    Stops if fails to locate only a single maximum until the vector reaches half the size of the x-array.
    Input: slope array (np.array), length of the x/z arrays (int)
    Output: list of the indexes of the maxima - preferably only one maximum (list), size of the convultion vector (int) '''
    conv_w=1
    rwf2=np.ones(conv_w)/conv_w
    dzdx_con=np.convolve(dzdx,rwf2,mode='same')
    max_indx=[]
    for i in range(len(dzdx_con)/4,len(dzdx_con)-len(dzdx_con)/4):  #limiting the location of the mid-point to the central half of the cross-section
        if (dzdx_con[i]>=0) and (dzdx_con[i+1]<=0):
            max_indx.append(i+1)
    while conv_w<(len_x/2) and len(max_indx)>1 :
        conv_w+=1
        rwf2=np.ones(conv_w)/conv_w
        dzdx_con=np.convolve(dzdx,rwf2,mode='same')
        max_indx=[]
        for i in range(len(dzdx_con)/4,len(dzdx_con)-len(dzdx_con)/4):
            if (dzdx_con[i]>=0) and (dzdx_con[i+1]<=0):
                max_indx.append(i+1)
    return max_indx,conv_w


def get_mins(bathy,dzdx,max_indx):
    '''Locates the (single) minimum point along each flank of the hill (seperated by the central maximum) - 2 points in total.
    Input: bathymetry array (np.array), slope array (np.array), index of the maximum point (int)
    Output: index of left flank minimum (int), index of right flank minimum (int), flag for success/failure (int) '''
    flag_mins=0 # 0 for success ; 1 for failure
    mid=max_indx[0]
    l_min=[]
    r_min=[]
    for li in range(mid-1):
        if (dzdx[li]<=0 and dzdx[li+1]>=0):
            l_min.append(li+1)
    for ri in range(mid,len(dzdx)-1):
        if dzdx[ri]<=0 and dzdx[ri+1]>=0:
            r_min.append(ri+1)
    for li2 in range (1,mid-2):
        sum3dzdx=(dzdx[li2-1]+dzdx[li2]+dzdx[li2+1])
        if dzdx[li2] not in l_min and sum3dzdx>=-0.1 and dzdx[li2]<=0 and abs(dzdx[li2-1])<0.1 and abs(dzdx[li2+1])<0.1:
            l_min.append(li2)
    for ri2 in range (mid+2,len(dzdx)-1):
        sum3dzdx=(dzdx[ri2-1]+dzdx[ri2]+dzdx[ri2+1])
        if dzdx[ri2] not in r_min and sum3dzdx>=-0.1 and dzdx[ri2]<=0 and abs(dzdx[ri2-1])<0.1 and abs(dzdx[ri2+1])<0.1:
            r_min.append(ri2)
    if len(l_min)>0 and len(r_min)>0:
        l_min_pnt=l_min[np.argmin(bathy[l_min])] #picks the deepest min point
        r_min_pnt=r_min[np.argmin(bathy[r_min])]
        low_prcnt=0.33
        min_p_max_hgt_l=min(bathy[l_min_pnt:mid])+(bathy[mid]-min(bathy[l_min_pnt:mid]))*low_prcnt
        min_p_max_hgt_r=min(bathy[mid:r_min_pnt+1])+(bathy[mid]-min(bathy[mid:r_min_pnt+1]))*low_prcnt
        for li3 in range(mid,l_min_pnt-1,-1):
            cond1=dzdx[li3-1]<=0 and dzdx[li3]>=0 and bathy[li3]<=min_p_max_hgt_l
            sum3dzdx=(dzdx[li3-1]+dzdx[li3]+dzdx[li3+1])
            cond2=sum3dzdx>=-0.1 and dzdx[li3]<=0 and abs(dzdx[li3-1])<0.1 and abs(dzdx[li3+1])<0.1 and bathy[li3]<=min_p_max_hgt_l
            if cond1:
                l_min_pnt=li3
                break
            if cond2:
                l_min_pnt=li3
                break  
        for ri3 in range(mid,r_min_pnt):
            cond1=dzdx[ri3]<=0 and dzdx[ri3+1]>=0 and bathy[ri3+1]<=min_p_max_hgt_r
            sum3dzdx=(dzdx[ri3-1]+dzdx[ri3]+dzdx[ri3+1])
            cond2=sum3dzdx>=-0.1 and dzdx[ri3]<=0 and abs(dzdx[ri3-1])<0.1 and abs(dzdx[ri3+1])<0.1 and bathy[ri3+1]<=min_p_max_hgt_r
            if cond1:
                r_min_pnt=ri3+1
                break
            if cond2:
                r_min_pnt=ri3
                break
        return l_min_pnt,r_min_pnt,flag_mins
    else:
        flag_mins=1
        return np.nan,np.nan,flag_mins


def get_top(l_min_pnt,r_min_pnt,bathy):
    '''Locates the top of the hill - the shallowest point between the 2 minima.
    Input: index of left flank minimum (int), index of right flank minimum (int), bathymetry array (np.array)
    Output: index of the top point (int)'''
    # *** Find Real Top of Hill ***
    if l_min_pnt!=r_min_pnt:
        real_top_pnt=l_min_pnt+bathy[l_min_pnt:r_min_pnt].argmax()
    else:
        real_top_pnt=l_min_pnt  #this will zero the resluts in the main code (cond_h1 in the main code will be FALSE)
    return real_top_pnt


def get_shapes(x_dist,bathy,dxdz,grd_spc,top_pnt,l_min_pnt,r_min_pnt):
    '''Calculates 4 parametrs of the shape of the flank (2 hill-flanks X 4 parametrs = 8 outputs). The parameters are 
    width, height, slope angle between the top of the hill and the flank minimum, maximum slope between two points 
    along the flank.
    Input: distance array (np.array), bathymetry array (np.array), slope array (np.array), resolution of the grid (int),
    index of the top point (int), index of left flank minimum (int), index of right flank minimum (int)
    Output: left width (float), right width (float), left height (float), right height (float), left slope angle (float),
    right slope angle (float), left maximum slope (float), right maximum slope (float)'''
    # *** Calculating Width of flanks  ***
    l_wdt=x_dist[top_pnt]-x_dist[l_min_pnt]
    r_wdt=x_dist[r_min_pnt]-x_dist[top_pnt]
    # *** Calculating Height of flanks  ***
    l_hgt=bathy[top_pnt]-bathy[l_min_pnt]
    r_hgt=bathy[top_pnt]-bathy[r_min_pnt]
    # *** Calculating Slope in 2 Ways ***
    # 1st - difference between the minima and top points  #
    minmax_slp_l = np.rad2deg(np.arctan(l_hgt/l_wdt))
    minmax_slp_r = np.rad2deg(np.arctan(r_hgt/r_wdt))
    # 2nd -maximum slope between two point, along the hill#
    max_slp_l = np.rad2deg(np.arctan(max(abs(dxdz[l_min_pnt:top_pnt]))))
    max_slp_r = np.rad2deg(np.arctan(max(abs(dxdz[top_pnt:r_min_pnt]))))
    # *** Calculating Area of flanks  ***
    l_area=abs(bathy[l_min_pnt]-bathy[l_min_pnt+1])*grd_spc/2000000. #[km^2] 
    for i in range(l_min_pnt+1,top_pnt):
        if bathy[i]==bathy[i+1]:
            l_area+=abs(bathy[i]-bathy[l_min_pnt])*grd_spc/1000000. #[km^2] 
        else:
            l_area+=(abs(bathy[i]-bathy[l_min_pnt])+abs(bathy[i+1]-bathy[l_min_pnt]))*grd_spc/2000000. #[km^2] 
    r_area=abs(bathy[r_min_pnt]-bathy[r_min_pnt-1])*grd_spc/2000000. #[km^2] 
    for i in range(r_min_pnt-1,top_pnt,-1):
        if bathy[i]==bathy[i-1]:
            r_area+=abs(bathy[i]-bathy[r_min_pnt])*grd_spc/1000000. #[km^2] 
        else:
            r_area+=(abs(bathy[i]-bathy[r_min_pnt])+abs(bathy[i-1]-bathy[r_min_pnt]))*grd_spc/2000000. #[km^2] 
    return l_wdt,r_wdt,l_hgt,r_hgt,minmax_slp_l,minmax_slp_r,max_slp_l,max_slp_r,l_area,r_area
