/********************************************************************************************/
/***** 'Death Forecasts Louisiana.sas' - Louisiana has long peaked, good candidate		*****/
/********************************************************************************************/


%let windowback=7;
%let target=Ohio;
data _null_ ;call symput("wordDte",trim(left(put("&sysdate9"d, worddatx32.)))); run;
%put worddte[&wordDte];

%let rc = %sysfunc(dlgcdir("/covid_analysis/modeling")); 
%include "../SAS_V2/MACROS.sas";
%let graphFormat=svg;

/********************************************************************/
/***** Update the JHU data from git site and run data load		*****/
/********************************************************************/

/* %UpdateJHUGit; */
/* %include "../SAS_V2/LoadTimeseries.sas"; */
/*
proc sql; select distinct cbsa_title,max(confirmed) as maxconfirmed from cbsa_trajectories group by cbsa_title order by maxconfirmed desc; quit;
*/
/************************************************************************/
/***** ARIMA Identification and Estimation Steps for xfer function	*****/
/************************************************************************/

/* Select states for analyisis */
data _modeldata;
	set state_trajectories(where=(province_state="&target")) end=eof;
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
		call symput('forecaststartline',intnx('day',filedate,-&windowback));
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


ods html close;ods rtf close;ods pdf close;ods document close;
options orientation=landscape papersize=letter nomprint nomlogic;
ods graphics on / reset height=8in width=10in imagemap outputfmt=svg imagefmt=svg tipmax=100000 ; 

ods html5  path="graphs" body="DeathsCCF_&target..htm" (url=none);

title 	   	  "SARS-CoV-2 Deaths Predicted by Case Transfer Function";
title2 	  h=1 "&target Updated &wordDte";
footnote j=c h=.95 "Data Source: Johns Hopkins University - https://github.com/CSSEGISandData/COVID-19 Data Updated: &sysdate";
footnote2 j=r h=0.5  "Samuel T. Croker - &sysdate9";

%let np=;
%let np =noprint;


proc ARIMA data=_modeldata(where=(filedate>'01mar20'd));
by province_state;
	identify &np var = dailycases(7) scan esacf p=(0:7) q=(0:7) stationarity=(adf=7 dlag=2); run;
	estimate &np p=1 q=(7)  noint  method=ml; run;	
	/* fit prewhitened series */
	identify  var = dailydeaths crosscorr=(dailycases) scan esacf p=(0:7) q=(0:7) nlag=60 ; run;
	/* estimate ccf */
	estimate  p=(1 7) q=1 noint input=(9 $ /(7) dailycases) method=ml;run;
	forecast id=filedate noprint out=_forecast back=0 lead=42 ;
quit;
data _plot;
	merge _forecast(in=a) _modeldata(in=b);
	by province_state filedate;
	if a ;
run;
proc sgplot data=_plot;
	label dailydeaths = "Deaths";
	label forecast = "Forecasted Deaths";
	label dif1_confirmed = "Cases";
	scatter x=filedate y=dailydeaths / filledoutlinedmarkers markerfillattrs=(color=darkred) markeroutlineattrs=(color=darkred thickness=1) markerattrs=(symbol=circlefilled size=10 );
	series x=filedate y=forecast /lineattrs=(thickness =2 color=darkblue);
	band x=filedate upper=u95 lower=l95 /transparency=.5 legendlabel="95% Prediction Interval";
	refline &forecaststartline /axis=x label='Multistep Forecast Start';
	series x=filedate y=dif1_confirmed /y2axis;
run;
quit;

ods html5 close;


