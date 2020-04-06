
%let rc = %sysfunc(dlgcdir("/covid_analysis"));

proc sort data=JHU_CORE_TS out=allcompose;
	by location filedate;
run;

proc means data=allcompose noprint;
	
	class location filedate/ order=data;
	var confirmed deaths;
	output out=allcompose_summary 
		(where=(_type_ = 3) )
		sum(confirmed deaths)=confirmed deaths;
	label confirmed="Confirmed Infections"
		  deaths="Deaths"
		  location='Location';
run;
/* sanity check - check for type 
proc sql; 
select _type_,count(*) as freq from allcompose_summary group by _type_ order by _type_;
select * from allcompose_summary where _type_ = 7 and location = 'Georgia-US';
quit;
*/



proc sort data=allcompose_summary;by location filedate;run;
data plotstate;
	set allcompose_summary;
	keep location confirmed deaths;
	by location filedate;
	if last.location and last.filedate then output; 
run;

proc sql noprint; 
	select distinct location into :smallstates separated by '","' from plotstate where confirmed between 100 and 800 and deaths>5; 
	select distinct location into :middlestates separated by '","' from plotstate where confirmed between 800 and 2500 and deaths>5; 
	select distinct location into :bigstates separated by '","' from plotstate where confirmed >= 2500 and deaths>5 ; 
	select distinct location into :usstates separated by '","' from plotstate where  location contains '-US' and confirmed > 1 and deaths > 1 ; 
quit;
data allcompose_summary; set allcompose_summary;
	if scan(location,1,":") ="Nation" then
		plotlabel=cats(scan(location,2,":"),"-",put(filedate,mmddyy5.));
	else
		plotlabel=cats(location,"-",put(filedate,mmddyy5.));
run;
/* Make the output destination BIG so you can zoom in */
options orientation=landscape papersize=(24in 24in) ;
ods graphics on / reset width=24in height=24in  imagemap outputfmt=svg;
ods html close;ods rtf close;ods pdf close;ods document close; 
ods html5 file="&outputpath./trajectories/ProvenceTrajectories.html" gpath= "&outputpath./trajectories" device=svg options(svg_mode="inline");
		title Province Trajectories;
	title2 Between 100 and 800 Total Cases;
	footnote 'Data Source: Johns Hopkins University - https://github.com/CSSEGISandData/COVID-19';
	proc sgplot data=allcompose_summary(where=(confirmed>10 and deaths > 2)) noautolegend;
		scatter x=Confirmed y=Deaths / group=location 
			datalabel=plotlabel
			markerattrs=(size=7) 
			datalabelattrs=(size=5) 
			transparency=0.25
			tip=(location filedate confirmed deaths);
		series x=Confirmed y=Deaths  / group=location 
			tip=(location filedate confirmed deaths);
		xaxis grid type=log min=0 LOGSTYLE=LINEAR ;
		yaxis grid type=log min=0 LOGSTYLE=LINEAR ;
		where location in ("&smallstates");
	run;
	
	/**************************************************************/
	title Province Trajectories;
	title2 Between 800 and 2500 Total Cases;
	proc sgplot data=allcompose_summary(where=(confirmed>50 and deaths > 5))  noautolegend;
		scatter x=Confirmed y=Deaths / group=location
			datalabel=plotlabel
			markerattrs=(size=7) 
			datalabelattrs=(size=5) 
			transparency=0.25
			tip=(location filedate confirmed deaths);
		series x=Confirmed y=Deaths  / group=location 
			tip=(location filedate confirmed deaths);
		xaxis grid type=log min=0  LOGSTYLE=LINEAR ;
		yaxis grid type=log min=0  LOGSTYLE=LINEAR ;
		where location in ("&middlestates");
	run;
	
	/**************************************************************/
	title Province Trajectories;
	title2 Greater Than 2500 Total Confirmed;
	proc sgplot data=allcompose_summary(where=(confirmed>100and deaths > 10))  noautolegend;
		scatter x=Confirmed y=Deaths / group=location
			datalabel=plotlabel
			markerattrs=(size=7) 
			datalabelattrs=(size=5) 
			transparency=0.25
			tip=(location filedate confirmed deaths);
		series x=Confirmed y=Deaths  / group=location 
			tip=(location filedate confirmed deaths);
		xaxis grid type=log min=0  LOGSTYLE=LINEAR;* values=(5 10 100 1000 10000 100000);
		yaxis grid type=log max=0  LOGSTYLE=LINEAR;* values=(5 10 100 500  1000 );
		where location in ("&bigstates");
	run;
ods html5 close;
ods graphics / reset;


options orientation=landscape papersize=(24in 24in) ;
ods graphics on / reset width=24in height=24in  imagemap outputfmt=svg;
ods html close;ods rtf close;ods pdf close;ods document close; 
ods html5 file="&outputpath./trajectories/USStateTrajectories.html" gpath= "&outputpath./trajectories" device=svg options(svg_mode="inline");
		title US States Trajectories;
	footnote 'Data Source: Johns Hopkins University - https://github.com/CSSEGISandData/COVID-19';
	%global maxconfirmed maxdeaths;
	%setmax(allcompose_summary,location in ("&usstates") and deaths > 10);
	proc sgplot 
		data=allcompose_summary(where=(location in ("&usstates") and deaths > 10)) noautolegend;
		scatter x=Confirmed y=Deaths / group=location 
			datalabel=plotlabel
			markerattrs=(size=7) 
			datalabelattrs=(size=5) 
			transparency=0.25
			tip=(location filedate confirmed deaths);
		series x=Confirmed y=Deaths  / group=location 
			tip=(location filedate confirmed deaths);
		xaxis grid type=log LOGSTYLE=LINEAR values=(200 1000 10000 10000 100000  );
		yaxis grid type=log LOGSTYLE=LINEAR values=(10 10 100 500  1000  10000   );
	run;
ods html5 close;
ods graphics / reset;

PROC DELETE DATA=ALLCOMPOSE ALLCOMPOSE_SUMMARY PLOTSTATE;
RUN;