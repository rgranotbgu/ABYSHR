function	[dist]=get_dist(lon,lat);

	d2r=pi/180;

	x=cos(d2r*lat).*cos(d2r*lon);
	y=cos(d2r*lat).*sin(d2r*lon);
	z=sin(d2r*lat);

	xp=[x(1);x(1:end-1)];
	yp=[y(1);y(1:end-1)];
	zp=[z(1);z(1:end-1)];

	dp=x.*xp+y.*yp+z.*zp;
	
	theta=real(acos(dp));

	dist=cumsum(theta*6371);
