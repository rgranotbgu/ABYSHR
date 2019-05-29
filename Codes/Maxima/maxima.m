clear all

%******* User-defined variables ********
azimin=2; %minimum azimuth for calculation. cant go lower than 2
azimax=30; %maximum azimuth for calculation. doesnt include the last. for 5 write 6 etc.

% parameters for gaussian denoising filter - to remove some false positives. Increase these two params
% to make filter stronger.
filtscale=0.8; %for gaussian denoise filter
filtsize=4; %for gaussian denoise filter. integer

threshold=5; %treshold for the magnitude of maximas wanted - increase to reject smaller magnitude hills
scale_min=0.5; %minimum width of hill wanted [km]
scale_max=1.7; %maximum width of hill wanted [km]
nscales=200; %number of wavelet scales
%***************************************


quads=load('../blacklist.asc'); %loads blacklist coordinations - to reject abyssal ridges found in a particular region.
orient=[4]; %for N-S track use 2. for E-W track use 4
track=[1]; %wanted track's numbers

for(tri=1:length(orient))
%***reads data from radon.out files into the variable 'data':
eval(['!ls -1 ../output/*.track' num2str(track(tri)) '.radon.out > infiles.track' num2str(track(tri))]);
fid=fopen(['infiles.track' num2str(track(tri))]);   
name=fgets(fid); %name of the radon.out file that will be inserted into data
data=[];
while(name>0)
	cmd=['temp=load(''' name(1:end-1) ''');'];
	eval(cmd);
	data=[data;temp];
	name=fgets(fid);
end
clear temp

data=sortrows(data,[orient(tri) 1]); %sort by either latitude (2) or longtitude (4)

xlen=179; %number of angles
ylen=length(data(:,1))/xlen; %number of different coordinates

x=unique(data(:,1));
temp=reshape(data(:,2),xlen,ylen)';
temp2=reshape(data(:,4),xlen,ylen)';
if(orient(tri)==2)
  [y,sorti,sortj]=unique(temp(:,1));
  x2=temp2(sorti,1);
  z=reshape(data(:,3),xlen,ylen)';
  z=z(sorti,:); %eliminating double values
end
if(orient(tri)==4)
  [x2,sorti,sortj]=unique(temp2(:,1)); 
  y=temp(sorti,1); 
  z=reshape(data(:,3),xlen,ylen)';

  z=z(sorti,:); %eliminating double value
end

%*** gaussian denoising filter:
filt=fspecial('gaussian',[filtsize filtsize],filtscale);
z=imfilter(z,filt,'replicate');

%***zeroing blacklist coordinates in z:
for zi=1:length(quads(:,1))
	zinds=find(x2>quads(zi,1) & x2<quads(zi,2) & y>quads(zi,3) & y<quads(zi,4));
	z(zinds,:)=0;
end
clear data

d=get_dist(x2,y); %the cumulative distance between points [km]

%*** creating arrays of distance , lon & lat  at length of power of 2:
mindom=min(d);
maxdom=max(d);
newlen=2^(ceil(log2(length(d))));
dom=linspace(mindom,maxdom,newlen);
domlon=interp1(d,x2,dom);
domlat=interp1(d,y,dom);
z(find(isnan(z)))=0; % zeroing NAN 

del_dom=dom(2)-dom(1); %distance difference of interpolation (dx)
b_min=log2(scale_min/(del_dom));
b_max=log2(scale_max/(del_dom));

%***calculatin the wavelate transform:
bathy_old=interp1(d,z(:,azimin-1)',dom);
cwt_old=wtrans(bathy_old,b_min,b_max,nscales)'; 
bathy=interp1(d,z(:,azimin)',dom);
cwt=wtrans(bathy,b_min,b_max,nscales)';

points=[];
bindex=azimin+1;
while(bindex<azimax+1)
	bindex
	bathy_new=interp1(d,z(:,bindex),dom);
	cwt_new=wtrans(bathy_new,b_min,b_max,nscales)';
	[maxes]=find_maxima(cwt_old,cwt,cwt_new,dom,domlon,domlat,linspace(b_min,b_max,nscales),quads);
	points=[points;maxes (bindex-1)*ones(size(maxes(:,1)))]; %add azimuth column to the maxima matrix
	bathy_old=bathy;
	cwt_old=cwt;
	bathy=bathy_new;
	cwt=cwt_new;
	bindex=bindex+1;
end	

outindex=find(points(:,4)>threshold);
points=points(outindex,:);
points(:,3)=2.^(points(:,3))*del_dom; %returns scale values back to km units

cmd=['save -ascii local_maxima.track' num2str(track(tri)) ' points'];
eval(cmd);

end