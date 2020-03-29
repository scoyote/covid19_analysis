
%let rc = %sysfunc(dlgcdir("/covid_analysis"));


*WORK.JHU20200327;
proc sort data=jhu_current out=allcompose;
	by location filedate;
run;

proc means data=allcompose noprint;
	class location filedate / order=data;
	var confirmed deaths;
	output out=allcompose_summary
		(where=(_type_ = 3) )
		sum(confirmed deaths)=confirmed deaths;
	label confirmed="Confirmed Infections"
		  deaths="Deaths"
		  location='Location';
run;


proc sort data=allcompose_summary;by location filedate;run;
data plotstate;
	set allcompose_summary;
	keep location confirmed deaths;
	by location filedate;
	if last.location and last.filedate then output; 
run;
proc sql; 
	select distinct location into :smallstates separated by '","' from plotstate where confirmed between 100 and 800 and deaths>5; 
	select distinct location into :middlestates separated by '","' from plotstate where confirmed between 800 and 2500 and deaths>5; 
	select distinct location into :bigstates separated by '","' from plotstate where confirmed >= 2500 and deaths>5 ; 
quit;

options orientation=landscape papersize=(26in 26in) ;
ods graphics / reset width=24in height=24in  imagemap ;
ods pdf file = "/covid_analysis/trajectory_Small.pdf"  ;
title Province Trajectories;
title2 Between 100 and 800 Total Cases;
footnote 'Data Source: Johns Hopkins University - https://github.com/CSSEGISandData/COVID-19';
proc sgplot data=allcompose_summary noautolegend;
	scatter x=Confirmed y=Deaths / group=location 
		datalabel=location 
		markerattrs=(size=7) 
		datalabelattrs=(size=5) 
		transparency=0.25
		tip=(location filedate confirmed deaths);
	series x=Confirmed y=Deaths  / group=location 
		tip=(location filedate confirmed deaths);
	xaxis grid type=log;
	yaxis grid type=log;
	where location in ("&smallstates");
run;
ods pdf close;

/**************************************************************/
ods pdf file = "/covid_analysis/trajectory_middle.pdf"  ;
title Province Trajectories;
title2 Between 800 and 2500 Total Cases;
proc sgplot data=allcompose_summary  noautolegend;
	scatter x=Confirmed y=Deaths / group=location
		datalabel=location 
		markerattrs=(size=7) 
		datalabelattrs=(size=5) 
		transparency=0.25
		tip=(location filedate confirmed deaths);
	series x=Confirmed y=Deaths  / group=location 
		tip=(location filedate confirmed deaths);
	xaxis grid type=log;
	yaxis grid type=log;
	where location in ("&middlestates");
run;
ods pdf close;
/**************************************************************/
ods pdf file = "/covid_analysis/trajectory_big.pdf"  ;
title Province Trajectories;
title2 Greater Than 2500 Total Confirmed;
proc sgplot data=allcompose_summary  noautolegend;
	scatter x=Confirmed y=Deaths / group=location
		datalabel=location 
		markerattrs=(size=7) 
		datalabelattrs=(size=5) 
		transparency=0.25
		tip=(location filedate confirmed deaths);
	series x=Confirmed y=Deaths  / group=location 
		tip=(location filedate confirmed deaths);
	xaxis grid type=log;
	yaxis grid type=log;
	where location in ("&bigstates");
run;
ods pdf close;
ods graphics / reset;

