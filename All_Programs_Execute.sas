/* clean up from previous runs if necessary */
proc datasets library=WORK kill; run; quit;

%let covidpath=/covid19data/csse_covid_19_data/csse_covid_19_daily_reports;
%let progpath=/covid_analysis;
%let outputpath=/covid_analysis/graphs/;

libname covid '/covid19data';   
libname fips "&progpath./data";        
filename covid19 "&covidpath";

/* load macros */
%include "&progpath./MACROS.sas";
/* Load Data */
%include "&progpath./HardLoadData.sas";

/* Run Analyses */
/*
%include "&progpath./PlotProvinces.sas";

%include "&progpath./GraphLocation.sas";
*/


/* keep the region name such that datasets match actual data name */
*****************************;
%let pvs=Indonesia;
%let suffix=;
/**********************************/
/********** ADJUSTMENTS ************/
/**********************************/
	%let adjust_type=0; /*set to 0 for no adjustment */
	%let adjust_date=20200330;
	%let adjust_confirmed=3032;
	%let adjust_deaths=102;
	%let adjust_note=;
	
	%let add_typer=0;
	%let add_date=20200331;
	%let add_confirmed=3929;
	%let add_deaths=111;
	
%include "&progpath./IndividualPlot.sas";
	