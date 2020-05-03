/********************************************************************/
/***** ALLStates.sas - Run through all the graphs from load-plot*****/
/********************************************************************/

%let rc = %sysfunc(dlgcdir("/covid_analysis/SAS_V2/")); 
%include "LoadTimeseries.sas";
%let graphFormat=svg;

/* *You will need to rerun part of loadtimeseries.sas after this; */
/* proc sql;  */
/* 	insert into US_AUGMENTEd  */
/* 			(province_state, filedate, confirmed, deaths)  */
/* 		values("Georgia", '23APR2020'd,21512,872) */
/* 	; */
/* quit; */
/*  */
/* %create_trajectories; */

/*

proc sql;
	select distinct cbsa_title from cbsa_trajectories 
	where lowcase(cbsa_title) contains "new york";
quit;
proc print data=state_trajectories;
	where province_state='Georgia';
	var filedate confirmed dif1_confirmed ma7_new_confirmed ma7_confirmed ;
run;

%plotstate(state=Georgia,level=state,plotback=30,gfmt=&graphFormat);

*/

/********************************************************************/
/***** Plot a single state group - just change the macvar here 	*****/
/********************************************************************/

%rmPathFiles(/covid_analysis/SAS_V2/graphs/graphs,&graphFormat);
%rmPathFiles(/covid_analysis/SAS_V2/graphs/,html);

/********************************************************************/
/***** Plot Regions and states	 								*****/
/********************************************************************/
ods html close;ods rtf close;ods pdf close;ods document close;

options orientation=landscape papersize=tabloid  nomprint nomlogic;

ods graphics on / reset  
	width=16in 
	height=10in
	imagemap 
	outputfmt=&graphFormat 
	imagefmt=&graphFormat;

ods pdf file="&outputpath./AllStatesAndCountries.pdf"; 
ods html5 file="&outputpath./AllStatesAndCountries.html" 
		gpath= "&outputpath./graphs/" (URL='graphs/')
		device=&graphFormat
		;*options(svg_mode="inline");

/* Countries */
%plotNations(maxplots=20);
/* States */
%plotUSStates(maxplots=20,xvalues=(5000 to 40000 by 5000),yvalues=(200 500 1000 1500 2000 2500 ));
/*  CBSAs  */
%plotCBSAs(maxplots=20, minconf=3000,mindeath=300,xvalues=(3000 to 43000 by 10000), yvalues=(300 to 3000 by 500));

ods html5 close; ods pdf close;

