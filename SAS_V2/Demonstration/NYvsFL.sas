
%let codepath=/repositories/covid19_analysis/SAS_V2/Demonstration;
%let rc = %sysfunc(dlgcdir("&codepath")); 
%include 'MACROS.sas';

libname pCovid '/repositories/covid19_analysis/SAS_V2/data';

proc sql;
	create table compjuly as
	select 
		province_state
		,reportdate
		,sum(dailyconfirmed) as dailycases
		,sum(dailydeaths) as dailydeaths
	from pcovid.us_daily
	where province_state in ("New York", "Florida","Texas","Georgia","South Carolina","North Carolina")
	group by province_state, reportdate
	order by province_state, reportdate
;
quit;
proc expand data=compjuly out=compjuly;
	by province_state;
	id reportdate;
	convert dailycases	= MA7_dailycases  / transout=(movave 7);
	convert dailycases	= totalcases  / transout=(cusum >0);
	convert dailydeaths	= MA7_dailydeaths  / transout=(movave 7);
	convert dailydeaths	= totaldeaths  / transout=(cusum >0);
run;
data compjuly; set compjuly;
run;

/* just slap a random walk on it. */
proc arima data=compjuly;
	identify noprint var=totalcases(1 1 7) scan minic esacf;
	estimate noprint p=3 q=2 noconstant method=cls;
	forecast noprint lead=14 back=0 alpha=0.05 id=reportdate interval=day out=_forecast;
	outlier;
	by Province_State;
	run;
quit;

proc arima data=compjuly;
	by Province_State;
	identify noprint var=totaldeaths(1 1 7 ) p=(0:10) q=(0:10) scan minic esacf;
	estimate noprint p=3 q=7 noconstant  method=ml;
	forecast noprint lead=14 back=0 alpha=0.05 id=reportdate interval=day out=_dforecast;
	outlier;
	run;
quit;


data _forecast; set _forecast;	
	by province_state reportdate;
	if missing(totalcases) then ff=forecast; else ff=.;
	if last.province_state then plotlabel=province_state;
	label ff="Forecast";
	format ff totalcases comma12.;
run;

data _mg; 
	merge _forecast(in=a where=(Province_State='Florida')  keep=reportdate Province_State ff rename=(ff=fa))
		  _forecast(in=b where=(province_state='New York') keep=reportdate Province_State ff rename=(ff=fb))
	;
	by reportdate;
	if a and b;
	if fa>fb and lag(fa)<=lag(fb) then do;
		flaglinelabel=put(reportdate,mmddyy5.);
		call symput('flagline',reportdate);
		call symput('flaglinelabel',flaglinelabel);
	end;

run;
%put flagline=&flagline &flaglinelabel;

data _null_ ;call symput("wordDte",trim(left(put("&sysdate9"d, worddatx32.)))); run;

ods html close;ods rtf close;ods pdf close;ods document close;
options orientation=landscape papersize=letter  nomprint nomlogic;
ods graphics on / reset width=10.5in height=8in imagemap outputfmt=svg imagefmt=svg; 
title 	  "DeSantis' Bane";
title2 	  "COVID19 Cases in New York and Florida Compared";
title3 	  h=.95 "Updated &wordDte";
footnote1 j=c "https://www.youtube.com/watch?v=LZ2OHfUAZcM";
footnote2 j=c h=1 "Beware of drawing conclusions from this data beyond the purpose for which it was generated.";
footnote3 j=c h=.95 "Data Source: Johns Hopkins University - https://github.com/CSSEGISandData/COVID-19 Data Updated: &sysdate";
footnote4 j=r h=0.5  "Samuel T. Croker - &sysdate9";
proc sgplot data=_forecast ;
	series x=reportdate y=totalcases 	 /smoothconnect group=province_state datalabel=plotlabel lineattrs=(pattern=solid thickness=4) colormodel=(darkred darkblue) tip=(province_state totalcases);
	series x=reportdate y=ff  			 /smoothconnect group=province_state datalabel=plotlabel lineattrs=(pattern=dots thickness=2) colormodel=(darkred darkblue) tip=(province_state ff);
	refline &flagline /axis=x lineattrs=(color=royalblue) label="&flaglinelabel";
	yaxis grid  offsetmin=1 offsetmax=1 	min=0 label="Total Cases";
	xaxis 				  offsetmin=0 offsetmax=.1 	min='01mar2020'd label="Report Date" ;
run;
quit;



ods html close;ods rtf close;ods pdf close;ods document close;
options orientation=landscape papersize=letter  nomprint nomlogic;
ods graphics on / reset width=10.5in height=8in imagemap outputfmt=svg imagefmt=svg; 
title 	  "DeSantis' Bane";
title2 	  "COVID19 Cases in New York, Texas, Georgia and Florida Compared";
title3 	  h=.95 "Updated &wordDte";
footnote1 j=c "https://www.youtube.com/watch?v=LZ2OHfUAZcM";
footnote2 j=c h=1 "Beware of drawing conclusions from this data beyond the purpose for which it was generated.";
footnote3 j=c h=.95 "Data Source: Johns Hopkins University - https://github.com/CSSEGISandData/COVID-19 Data Updated: &sysdate";
footnote4 j=r h=0.5  "Samuel T. Croker - &sysdate9";
proc sgplot data=_forecast ;
	series x=reportdate y=totalcases 	 /smoothconnect group=province_state datalabel=plotlabel lineattrs=(pattern=solid thickness=4) colormodel=(darkred darkblue) tip=(province_state totalcases);
	series x=reportdate y=ff  			 /smoothconnect group=province_state datalabel=plotlabel lineattrs=(pattern=dots thickness=2) colormodel=(darkred darkblue) tip=(province_state ff);
	yaxis grid  offsetmin=1 offsetmax=1 	min=0 label="Total Cases";
	xaxis 				  offsetmin=0 offsetmax=.1 	min='01mar2020'd label="Report Date" ;
run;
quit;


data _dforecast; set _dforecast;	
	by province_state reportdate;
	if missing(totaldeaths) then ff=forecast; else ff=.;
	if last.province_state then plotlabel=province_state;
	label ff="Forecast";
	format ff totaldeaths comma12.;
run;

ods html close;ods rtf close;ods pdf close;ods document close;
options orientation=landscape papersize=letter  nomprint nomlogic;
ods graphics on / reset width=10.5in height=8in imagemap outputfmt=svg imagefmt=svg; 
title1	  "COVID19 Deaths in New York and Florida Compared";
title2 	  h=.95 "Updated &wordDte";
footnote1 j=c "https://www.youtube.com/watch?v=LZ2OHfUAZcM";
footnote2 j=c h=1 "Beware of drawing conclusions from this data beyond the purpose for which it was generated.";
footnote3 j=c h=.95 "Data Source: Johns Hopkins University - https://github.com/CSSEGISandData/COVID-19 Data Updated: &sysdate";
footnote4 j=r h=0.5  "Samuel T. Croker - &sysdate9";
proc sgplot data=_dforecast ;
	series x=reportdate y=totaldeaths	/smoothconnect group=province_state datalabel=plotlabel lineattrs=(pattern=solid thickness=4) colormodel=(darkred darkblue) tip=(province_state totaldeaths);
	series x=reportdate y=ff			/smoothconnect group=province_state datalabel=plotlabel lineattrs=(pattern=dots thickness=2) colormodel=(darkred darkblue) tip=(province_state ff);
	yaxis grid  offsetmin=1 offsetmax=1 	min=0 label="Total Cases";
	xaxis 				  offsetmin=0 offsetmax=.1 	min='01mar2020'd label="Report Date" ;
run;
quit;



