#include <stdio.h>
#include <math.h>
#include "radon.h"


#define PI 3.14159265359
#define AVE_RADIUS 10000.0
#define RMS_RADIUS 20000.0
#define INC_RADIUS 10000.0
#define EARTH_RADIUS 6371000.0
#define D2R (3.14159265359/180)
#define NUMSLOPE 179
#define MINANG -89.0
#define MAXANG 89.0


static double	data[NUMY][NUMX]; //note that the array is [Y][X], not the opposite
static double	datax[NUMX];
static double	datay[NUMY];
static double	radon[NUMTRACK][NUMSLOPE];
static double	slope[NUMSLOPE];
static double	track[NUMTRACK][2];


void 	make_slope(double *slope_ptr);
double 	linesum(double *xgrid,double *ygrid,double slope,double *data_ptr,
		double data_av);
void 	proj_cart(double refx,double refy,double *datax_ptr,double *datay_ptr,
                  double *x_dom,double *y_dom);
void	make_grid(double *xdom,double delx,double *xgrid,int num);
void	array_mult_const(double *in_array,double scalar,double *out_array,
		         int num);
int	combine_sort_purge(double *xgrid,double *xgridy,double *ygrid,
			   double *ygridx,double *outx,double *outy,
			   double slope);
double	line_int(double *pointsx,double *pointsy,int num_points,
		 double *xgrid,double *ygrid,double *data_ptr,double data_av);
int	find_index(double point,double *grid);
void	data_stats(double *data_ptr,double refx,double refy,double *datax_ptr,
		  double *datay_ptr,double *stats_ptr);

int main(){
	int	i,j,k;
	FILE	*data_file;
	FILE	*track_file;
	FILE	*x_file;
	FILE	*y_file;
	FILE	*stat_file;
	char	line[60];
	double	stats[10];
	double 	xdom[NUMX];
	double 	ydom[NUMY];
	double	delx,dely;
	double	xgrid[NUMX+1];
	double	ygrid[NUMY+1];
	
	x_file=fopen("tempx","r");
	y_file=fopen("tempy","r");
	data_file=fopen("tempz","r");
	track_file=fopen("tempt","r");
	stat_file=fopen(STAT_FILE,"w");

	for(i=0;i<NUMX;++i){
		fgets(line,sizeof(line),x_file);
		sscanf(line,"%lf",&datax[i]);
	}
	for(i=0;i<NUMY;++i){
		fgets(line,sizeof(line),y_file);
		sscanf(line,"%lf",&datay[i]);
	}
	for(j=0;j<NUMX;++j){
		for(i=0;i<NUMY;++i){
			fgets(line,sizeof(line),data_file);
			sscanf(line,"%lf",&data[i][j]);
		}
	}
	for(i=0;i<NUMTRACK;++i){
		fgets(line,sizeof(line),track_file);
		sscanf(line,"%lf %lf",&track[i][0],&track[i][1]);
	}

	make_slope(slope);
	i=0;
	k=0;
	for(i=0;i<NUMTRACK;++i){
		fprintf(stderr,"Working on track point %d of %d\r",i+1,NUMTRACK);
		fflush(stderr);
		data_stats((double *)data,track[i][0],track[i][1],datax,datay,stats);
		fprintf(stat_file,"%lf %lf %d %lf %lf %lf %lf %d %lf %lf %lf %lf\n",track[i][0],track[i][1],(int)stats[0],stats[1],stats[2],stats[3],stats[4],(int)stats[5],stats[6],stats[7],stats[8],stats[9]);
		proj_cart(track[i][0],track[i][1],datax,datay,xdom,ydom);
		delx=xdom[1]-xdom[0]; 
		dely=ydom[1]-ydom[0]; 
		make_grid(xdom,delx,xgrid,NUMX);
		make_grid(ydom,dely,ygrid,NUMY);
	  	for(k=0;k<NUMSLOPE;++k){
	    		radon[i][k]=linesum(xgrid,ygrid,slope[k],(double *)data,stats[1]);
				printf("%lf %lf %lf %lf\n",90-atan(slope[k])/D2R,track[i][1],radon[i][k],track[i][0]);
		}
	}
	fprintf(stderr,"\n");
	
}

///////// create slope array running from tan (theta = -89 degrees) to tan (theta = 89 degrees).
void make_slope(double *slope_ptr){
	int	index;

	for(index=0;index<NUMSLOPE;++index){
		*(slope_ptr+index)=tan(D2R*(MINANG+(MAXANG-MINANG)
				*index/(NUMSLOPE-1)));
	}
}

//////// create stats for the data - calculate only for real data.
void	data_stats(double *data_ptr,double refx,double refy,double *datax_ptr,
		  double *datay_ptr,double *stats_ptr){
	int		i,j;
	double 		distx,disty;
	double 		data_sum;
	double		data_sq_sum;
	int		num_sum;
	double 		data_sum2;
	double		data_sq_sum2;
	int		num_sum2;
	double		bn1;
	double		bn2;
	
	data_sum=0;
	num_sum=0;
	data_sq_sum=0;
	data_sum2=0;
	num_sum2=0;
	data_sq_sum2=0;
	for(i=0;i<NUMX;i++){ //nested loop running on columns, not on rows
		distx=(*(datax_ptr+i)-refx)*(D2R*EARTH_RADIUS)*cos(D2R*refy); 
		for(j=0;j<NUMY;j++){
			disty=(*(datay_ptr+j)-refy)*D2R*EARTH_RADIUS;
			if(((disty*disty+distx*distx)<(AVE_RADIUS*AVE_RADIUS) && (*(data_ptr+j*NUMX+i)<0))){ //if the distance from track is less than the beam radius and there is real depth data
				data_sum=data_sum+*(data_ptr+j*NUMX+i);
				++num_sum; 
				data_sq_sum=data_sq_sum+(*(data_ptr+j*NUMX+i))*(*(data_ptr+j*NUMX+i)); 
			}
			if(((disty*disty+distx*distx)<(RMS_RADIUS*RMS_RADIUS) && (*(data_ptr+j*NUMX+i)<0))){ //if the distance from track is less than the RMS depth and there is real depth data
				data_sum2=data_sum2+*(data_ptr+j*NUMX+i); 
				++num_sum2; 
				data_sq_sum2=data_sq_sum2+(*(data_ptr+j*NUMX+i))*(*(data_ptr+j*NUMX+i)); 
			}

		}
	}
	//calculation of RMS bathymetry - 10 km radius//
	*stats_ptr=num_sum; 
	*(stats_ptr+1)=data_sum/num_sum; 
	*(stats_ptr+3)=sqrt(data_sq_sum/num_sum-(*(stats_ptr+1) * *(stats_ptr+1)));
	*(stats_ptr+2)=*(stats_ptr+3)*num_sum/(num_sum-1); 
	*(stats_ptr+4)=*(stats_ptr+3)/(sqrt(2*num_sum)); 
	//calculation of RMS bathymetry - 20 km radius//
	*(stats_ptr+5)=num_sum2;
	*(stats_ptr+6)=data_sum2/num_sum2; 
	*(stats_ptr+8)=sqrt(data_sq_sum2/num_sum2-(*(stats_ptr+6) * *(stats_ptr+6))); 
	*(stats_ptr+7)=*(stats_ptr+8)*num_sum2/(num_sum2-1); 
	*(stats_ptr+9)=*(stats_ptr+8)/(sqrt(2*num_sum2)); 
}
				
double 	linesum(double *xgrid,double *ygrid,double slope,double *data_ptr,
	        double data_av){
	double	line_int_gridx[NUMX+1];
	double	line_int_gridy[NUMY+1];
	int	num_points,i;
	double	pointsx[NUMX+NUMY];
	double	pointsy[NUMX+NUMY];
	double	radon_val;	
	array_mult_const(xgrid,slope,line_int_gridx,NUMX+1);
	array_mult_const(ygrid,1/slope,line_int_gridy,NUMY+1);
	num_points=combine_sort_purge(xgrid,line_int_gridx,ygrid,
		line_int_gridy,pointsx,pointsy,slope);
	radon_val=line_int(pointsx,pointsy,num_points,xgrid,ygrid,data_ptr,
			   data_av);
	return(radon_val);
}
	
void 	proj_cart(double refx,double refy,double *datax_ptr,double *datay_ptr,double *xdom,double *ydom){
	int	j;

	for(j=0;j<NUMY;++j){
		*(ydom+j)=(*(datay_ptr+j)-refy)*(D2R*EARTH_RADIUS);
	}
	for(j=0;j<NUMX;++j){
		*(xdom+j)=(*(datax_ptr+j)-refx)*(D2R*EARTH_RADIUS
		          *cos(D2R*refy));
	}
}
	
void	make_grid(double *dom,double del,double *grid,int num){
	int j;
	
	*grid=*dom-del/2;
	for(j=0;j<num;++j){
		*(grid+j+1)=*(dom+j)+del/2;
	}
}

void	array_mult_const(double *in_array,double scalar,double *out_array,int num){
	int j;

	for(j=0;j<num;++j){
		*(out_array+j)=*(in_array+j)*scalar;
	}
}


int	combine_sort_purge(double *xgrid,double *xgridy,double *ygrid,double *ygridx,double *outx,double *outy,double slope){
	int 	i,j,k;
	int	inc;
	double	*start_ptr1,*start_ptr2;
	double	pointx,pointy;
	
	start_ptr1=ygridx;
	start_ptr2=ygrid;
	inc=1;
	if(slope<0){
		start_ptr1=ygridx+NUMY;
		start_ptr2=ygrid+NUMY;
		inc=-1;
	}

	i=0;
	j=0;
	k=0;
	while((i<=NUMX) || (j<=NUMY)){
		if((*(xgrid+i)<*(start_ptr1+j*inc)) && (i<=NUMX)){
			pointx=*(xgrid+i);
			pointy=*(xgridy+i);
			i++;
		}else if((*(start_ptr1+j*inc)<*(xgrid+i)) && (j<=NUMY)){
			pointx=*(start_ptr1+j*inc);
			pointy=*(start_ptr2+j*inc);
			j++;
		}else if((*(xgrid+i)==*(start_ptr1+j*inc)) && (j<=NUMY) && 
			 (i<NUMX)){
			pointx=*(xgrid+i);
			pointy=*(xgridy+i);
			i++;
			j++;
		}else if((j>=NUMY) && (i<=NUMX)){
			pointx=*(xgrid+i);
			pointy=*(xgridy+i);
			i++;
		}else if((i>=NUMX) && (j<=NUMY)){
			pointx=*(start_ptr1+j*inc);
			pointy=*(start_ptr2+j*inc);
			j++;
		}
		if(((pointy*pointy+pointx*pointx)<(INC_RADIUS*INC_RADIUS)) &&
		   (pointx>=*xgrid) && (pointx<=*(xgrid+NUMX-1)) &&
		   (pointy>=*ygrid) && (pointy<=*(ygrid+NUMY-1))){
			*(outx+k)=pointx;
			*(outy+k)=pointy;
			k++;
		}
	}
	return(k);	
}

double	line_int(double *pointsx,double *pointsy,int num_points,
		 double *xgrid,double *ygrid,double *data_ptr,double data_av){
	int	n,m,i,j;
	double	local_distance,total_distance;
	double	midpointx,midpointy;
	double	data_val;
	double	radon_val;

	total_distance=0;
	radon_val=0;
	for(i=0;i<num_points-1;++i){
		local_distance=sqrt((*(pointsx+i+1)-*(pointsx+i))
				   *(*(pointsx+i+1)-*(pointsx+i))
				   +(*(pointsy+i+1)-*(pointsy+i))
				   *(*(pointsy+i+1)-*(pointsy+i)));
		midpointx=0.5*(*(pointsx+i+1)+*(pointsx+i));
		midpointy=0.5*(*(pointsy+i+1)+*(pointsy+i));
		m=find_index(midpointx,xgrid);
		n=find_index(midpointy,ygrid);
		data_val=*(data_ptr+n*NUMX+m);
		if(data_val<99000){
			radon_val=radon_val+(data_val-data_av)*local_distance;
			total_distance=total_distance+local_distance;
		}
	}
	radon_val=radon_val/total_distance;
	return(radon_val);
}

int	find_index(double point,double *grid){
	int	i;
	
	i=0;
	if((*(grid+1)-*grid)>0){
		while(point>*(grid+i)){
			++i;
		}
		return(i-1);
	}else if((*(grid+1)-*grid)<0){
		while(point<*(grid+i)){
			++i;
		}
		return(i-1);
	}
}
