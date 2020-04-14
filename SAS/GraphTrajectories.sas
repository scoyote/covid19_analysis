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

	select distinct location into :usstates1 separated by '","' 
		from plotstate 
		where location contains '-US' 
			and confirmed <= 2500 
			and deaths <=  100 
			and location ~='King County, WA-US'; 
	select distinct location into :usstates3 separated by '","' 
		from plotstate 
		where location contains '-US' 
			and confirmed > 2500 
			and deaths > 100 ; 
quit;
proc sort data=allcompose_summary;
	by location descending filedate;
run;

data allcompose_summary; set allcompose_summary;
	by location descending filedate;
	if first.location then obscount=0;
	obscount+1;
	if deaths=0 then deaths =1.1;
	plotid=cats(location,obscount);
	if obscount <=7 then do;
		if scan(location,1,":") ="Nation" then do;
			plotlabel=cats(scan(location,2,":"),"-",put(filedate,mmddyy5.));
		end;
		else do;
			plotlabel=cats(location,"-",put(filedate,mmddyy5.));
		end;
		plotflag='Y';
	end;
	else plotflag='N';
run;


proc sort data=allcompose_summary; by location filedate; run;

/* Make the output destination BIG so you can zoom in */
options orientation=landscape papersize=(11in 8.5in) ;
ods graphics on / reset width=10.5in height=8in  imagemap outputfmt=svg;
ods html close;ods rtf close;ods pdf close;ods document close; 
ods html5 file="&outputpath./trajectories/ProvenceTrajectories_Small.html" gpath= "&outputpath./trajectories" device=svg options(svg_mode="inline");
	title Province Trajectories;
	title2 Between 100 and 800 Total Cases;
	footnote 'Data Source: Johns Hopkins University - https://github.com/CSSEGISandData/COVID-19';
	proc sgplot data=allcompose_summary(where=(confirmed>10 and deaths > 2 and plotflag='Y')) noautolegend;
		format filedate mmddyy5.
			   confirmed comma10.
			   deaths comma10.;
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
	ods html5 close;
	ods html5 file="&outputpath./trajectories/ProvenceTrajectories_Mid.html" gpath= "&outputpath./trajectories" device=svg options(svg_mode="inline");
	/**************************************************************/
	title Province Trajectories;
	title2 Between 800 and 2500 Total Cases;
	proc sgplot data=allcompose_summary(where=(confirmed>50 and deaths > 5 and plotflag='Y'))  noautolegend;
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
	
	ods html5 close;
	ods html5 file="&outputpath./trajectories/ProvenceTrajectories_Large.html" gpath= "&outputpath./trajectories" device=svg options(svg_mode="inline");
	/**************************************************************/
	title Province Trajectories;
	title2 Greater Than 2500 Total Confirmed;
	proc sgplot data=allcompose_summary(where=(confirmed>100and deaths > 10 and plotflag='Y'))  noautolegend;
		format filedate mmddyy5.
			   confirmed comma10.
			   deaths comma10.;
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


options orientation=landscape papersize=(11in 8.5in) ;
ods graphics on / reset width=10.5in height=8in  imagemap imagename="USStates_trajectories" outputfmt=svg ;
ods html close;ods rtf close;ods pdf close;ods document close; 
ods html5 file="&outputpath./trajectories/USStateTrajectories_Low.html" gpath= "&outputpath./trajectories" device=svg options(svg_mode="inline");
	title US States Trajectories Low Prevalence;
	footnote 'Data Source: Johns Hopkins University - https://github.com/CSSEGISandData/COVID-19';
	%global maxconfirmed maxdeaths;
	%setmax(allcompose_summary,location in ("&usstates1") and deaths > 0 );
	proc sgplot 
		data=allcompose_summary(where=(location in ("&usstates1") and deaths > 5 and plotflag='Y')) noautolegend;
		format filedate mmddyy5.
			   confirmed comma10.
			   deaths comma10.;
		scatter x=Confirmed y=Deaths / group=location 
			datalabel=plotlabel
			markerattrs=(size=7) 
			datalabelattrs=(size=5) 
			transparency=0.25
			tip=(location filedate confirmed deaths);
		series x=Confirmed y=Deaths  / group=location 
			tip=(location filedate confirmed deaths);
		xaxis grid minorgrid type=log LOGSTYLE=logexpand;* values=(100 500 to 5000 by 1000  );
		yaxis grid minorgrid type=log LOGSTYLE=logexpand;* values=(2 5 10 to 100 by 10  );
	run;
	ods html5 close;
	
	ods html5 file="&outputpath./trajectories/USStateTrajectories_High.html" gpath= "&outputpath./trajectories" device=svg options(svg_mode="inline");
	title US States Trajectories High Prevalence;
	footnote 'Data Source: Johns Hopkins University - https://github.com/CSSEGISandData/COVID-19';
	%global maxconfirmed maxdeaths;
	%setmax(allcompose_summary,location in ("&usstates3") and deaths > 10 );
	proc sgplot 
		data=allcompose_summary(where=(location in ("&usstates3") and deaths > 10 and plotflag='Y')) noautolegend;
		format filedate mmddyy5.
			   confirmed comma10.
			   deaths comma10.;
		scatter x=Confirmed y=Deaths / group=location 
			datalabel=plotlabel
			markerattrs=(size=7) 
			datalabelattrs=(size=5) 
			transparency=0.25
			tip=(location filedate confirmed deaths);
		series x=Confirmed y=Deaths  / group=location 
			tip=(location filedate confirmed deaths);
		xaxis grid minorgrid type=log LOGSTYLE=logexpand;* values=(200 1000 10000 10000 100000  );
		yaxis grid minorgrid type=log LOGSTYLE=logexpand;* values=(10 10 100 500  1000  10000   );
	run;
ods html5 close;
ods graphics / reset;

/* PROC DELETE DATA=ALLCOMPOSE ALLCOMPOSE_SUMMARY PLOTSTATE; */
/* RUN; */