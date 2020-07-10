data _colors;
/* 	array cols{5} $ _temporary_ ('FF','CC','99','33','00'); */
/* 	array cols{3} $ _temporary_ ('FF','CC','E5'); */
	array cols{3} $ _temporary_ ('FF','CC','E5');

	value=0;
	retain id 'c_ramp';
	do i=1 to dim(cols);
		do j=1 to dim(cols);
			do k=1 to dim(cols);
				if i=j and j=k and i=j then continue;
				value+1;
				color=compress('CX'||cols[i]||cols[j]||cols[k]);
				drop i j k;
				fillcolor=color;
				linecolor=color;
				output;
			end;
		end;
	end;
run;
proc sort data=_colors; by value; run;

data _series;
	set _colors;
	by value;
	do x = 1 to 10;
		if x=10 then plotlabel=color;
		output;
	end;
run;

data _colors;
	set _colors(drop=value);
	value = color;
run;	

options orientation=portrait papersize=letter  nomprint nomlogic;
ods graphics on / reset width=8in height=20in imagemap outputfmt=svg imagefmt=svg tipmax=100000 ; 

proc sgplot data=_series dattrmap=_colors noautolegend;
	series x=x y=value / group=color datalabel=plotlabel lineattrs=(pattern=solid thickness=5 ) attrid=c_ramp tip=(color);
	xaxis;
	yaxis;
run;
quit;
