/********************************************************************************************/
/***** 'Death Forecasts Louisiana.sas' - Louisiana has long peaked, good candidate		*****/
/********************************************************************************************/

%let rc = %sysfunc(dlgcdir("/covid_analysis/SAS_V2/")); 
%include "MACROS.sas";
%let graphFormat=svg;

/********************************************************************/
/***** Update the JHU data from git site and run data load		*****/
/********************************************************************/

%UpdateJHUGit;
%include "LoadTimeseries.sas";


/************************************************************************/
/***** ARIMA Identification and Estimation Steps for xfer function	*****/
/************************************************************************/

/* Select states for analyisis */
data _modeldata;
	set state_trajectories(where=(province_state='Georgia')) end=eof;
	retain maxs nrow;
	dailydeaths = sum(int(dif1_deaths),0);
	dailycases  = sum(int(dif1_confirmed),0);
	
	if _n_=0 then maxs=0;
	if _N_>1 then do;
		if dif1_confirmed>maxs then do;
			maxs=dif1_confirmed;
			nrow=_n_;
		end;
	end;
	if eof then do;
		put "NOTE: " maxs= nrow=;
		call symput("nrow", nrow);
		call symput("maxfiledate", filedate);
	end;
	output;
run;
data _modeldata;
	set _modeldata;
	if _n_ = &nrow then nlag=0;
	else if _n_>&nrow then nlag+1;
	else nlag=.;
	if ~missing(dailycases) and ~missing(dailydeaths);
run;
proc sort data=_modeldata; by filedate; run;
ods graphics on /reset=all height=4in width=8in;
proc sgplot data=_modeldata;
	series y=dailydeaths x=filedate / datalabel=nlag y2axis markers;
	series y=dailycases x=filedate  / markers;
run;quit;

/* Explore ARIMA */

proc ARIMA data=_modeldata;
	identify noprint var = dailycases scan esacf ; run;
	estimate noprint p=1 q=3 noconstant method=ml; run;	

	identify var = dailydeaths crosscorr=(dailycases)  scan esacf nlag=30; run;

	estimate p=2 q=2 input=(4 $ (1)/ dailycases) noconstant method=ml;run;
	forecast id=filedate noprint out=_forecast back=20 lead=40  ;
quit;

%put &maxfiledate;

proc sgplot data=_forecast;
	scatter x=filedate y=dailydeaths /markerattrs=(color=darkred);
	series x=filedate y=forecast;
	band x=filedate upper=u95 lower=l95 /transparency=.6;
	refline &maxfiledate /axis=x;
run;
quit;


