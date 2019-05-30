#!/usr/bin/perl


$file="$ARGV[0].multibeam";
$output="$ARGV[0].$ARGV[5].radon";

open IN, "$ARGV[0].$ARGV[5].radon.out";
$minx=99999;
$maxx=-99999;
$miny=99999;
$maxy=-99999;
$ind=0;
$numy=0;
$numx=0;
$oldy=-99999;
$col=1;
if($ARGV[6]==1){$col=3;}
while($line=<IN>){
	chomp($line);
	@parts=split /\s+/, $line;
	if($parts[0]<$minx){$minx=$parts[0];}
	if($parts[0]>$maxx){$maxx=$parts[0];}
	if($parts[$col]<$miny){$miny=$parts[$col];}
	if($parts[$col]>$maxy){$maxy=$parts[$col];}
	if($parts[$col]!=$oldy){
		$numy++;
		$oldy=$parts[$col];
	}
	if($numy==1){
		$numx++;
	}
}
$delx=($maxx-$minx)/$numx;
$dely=($maxy-$miny)/$numy;

$nimy=$miny;
$naxy=$maxy;
$proj2="-JX3/22.9";
$reg2="-R$minx/$maxx/$miny/$maxy";
$int2="-I$delx/$dely";
$ano2="-B30g30/0.1";
$col2=$col+1;
system("./blacklist2.pl $output.out blacklist.asc");
system("awk '{print \$1,\$$col2,\$3}' $output.out.bl | gmt surface -G$output.grd $reg2 $int2 ");
system("gmt grdgradient $output.grd -G$output.grad -A45 -Ne0.3");
system("gmt grdimage $output.grd $reg2 -X12 $proj2 $ano2 -I$output.grad -Cradon.cpt  --FORMAT_GEO_OUT=D --FORMAT_GEO_MAP=D >$output.bl.ps");
system("awk '{print \$1,\$$col2,\$3}' $output.out | gmt surface -G$output.grd $reg2 $int2 ");
system("gmt grdgradient $output.grd -G$output.grad -A45 -Ne0.3");
system("gmt grdimage $output.grd $reg2 -X12 $proj2 $ano2 -I$output.grad -Cradon.cpt  --FORMAT_GEO_OUT=D --FORMAT_GEO_MAP=D >$output.ps");
close(IN);
system("ps2epsi $output.ps $output.eps");
system("ps2epsi $output.bl.ps $output.bl.eps");

$output="$ARGV[0].$ARGV[5].multibeam";
open IN, "$ARGV[0].multibeam.asc.bl";
for($i=0;$i<4;$i++){<IN>;}
$minx=99999;
$maxx=-99999;
$miny=99999;
$maxy=-99999;
$ind=0;
$numy=0;
$numx=0;
$oldx=-99999;
while($line=<IN>){
	chomp($line);
	$line=~s/^\s+//;
	@parts=split /\s+/, $line;
	if($parts[0]<$minx){$minx=$parts[0];}
	if($parts[0]>$maxx){$maxx=$parts[0];}
	if($parts[1]<$miny){$miny=$parts[1];}
	if($parts[1]>$maxy){$maxy=$parts[1];}
	if($parts[0]!=$oldx){
		$numx++;
		$oldx=$parts[0];
	}
	if($numx==1){
		$numy++;
	}
}
$delx=($maxx-$minx)/$numx;
$dely=($maxy-$miny)/$numy;

$reg1="-R$ARGV[1]/$ARGV[2]/$ARGV[3]/$ARGV[4]";
$reg2="-R$minx/$maxx/$miny/$maxy";

$real_disty=($ARGV[4]-$ARGV[3])*6371000*3.14159265359/180;
$real_distx=($ARGV[2]-$ARGV[1])*6371000*3.14159265359/180*cos(($ARGV[4]-$ARGV[3])/2*3.14159265359/180);
$proj_wid=15;
if($real_disty>$real_distx){
	$proj_wid=$real_distx/$real_disty*15;
}
$proj1="-JM$proj_wid";
$ano1="-B0.5/0.2";
$xyzfile="$ARGV[0].$ARGV[5].radon.out";
$int2="-I$delx/$dely";
system("awk '{if(\$3>0){print \$1,\$2,\"NaN\"}else{print \$1,\$2,\$3}}' $file.asc >$file.asci");
system("gmt xyz2grd $file.asci -h4 -G$file.grd $reg2 $int2 -r");
system("gmt grdgradient $file.grd -G$file.grad -A45 -Ne0.3");
system("gmt grdimage $file.grd $reg1 $proj1 $ano1 -Cmultibeam.cpt -I$file.grad -Xc -Yc -K -P --FORMAT_GEO_OUT=D --FORMAT_GEO_MAP=D >$output.ps");
system("gmt psxy $ARGV[5] -W2 -O $reg1 $proj1 >>$output.ps");
system("awk '{if(\$3>0){print \$1,\$2,\"NaN\"}else{print \$1,\$2,\$3}}' $file.asc.bl >$file.asci");
system("gmt xyz2grd $file.asci -h4 -G$file.grd $reg2 $int2 -r");
system("gmt grdgradient $file.grd -G$file.grad -A45 -Ne0.3");
system("gmt grdimage $file.grd $reg1 $proj1 $ano1 -Cmultibeam.cpt -I$file.grad -Xc -Yc -K -P --FORMAT_GEO_OUT=D --FORMAT_GEO_MAP=D >$output.bl.ps");
system("gmt psxy $ARGV[5] -W2 -O $reg1 $proj1 >>$output.bl.ps");


system("ps2epsi $output.ps $output.eps");
system("ps2epsi $output.bl.ps $output.bl.eps");
