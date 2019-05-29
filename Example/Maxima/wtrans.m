function	[out]=wtrans(bathy,b_min,b_max,nscales);

	xhat=fft(bathy);
        n=length(bathy);
        xi=[0:n/2 -n/2+1:-1]*2*pi/n; %intial omega array [omega=2*pi*f]
        k=1;
        for b=linspace(b_min,b_max,nscales)
                a=2^b;
                omega=xi*a;
                window=omega.^2.*exp(-omega.^2/2);
                window=window*sqrt(a);
                what=xhat.*window;
                w=ifft(what);
                out(1:n,k)=real(w)';
                k=k+1;
        end

