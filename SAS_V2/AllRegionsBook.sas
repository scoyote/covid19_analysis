/********************************************************************/
/***** ALLStates.sas - Run through all the graphs from load-plot*****/
/********************************************************************/

%let rc = %sysfunc(dlgcdir("/covid_analysis/SAS_V2/")); 
%include "MACROS.sas";
%let graphFormat=svg;

/********************************************************************/
/***** Update the JHU data from git site and run data load		*****/
/********************************************************************/

%UpdateJHUGit;
%include "LoadTimeseries.sas";

/********************************************************************/
/***** Clean up the old html and graphs						 	*****/
/********************************************************************/

%rmPathFiles(/covid_analysis/SAS_V2/graphs/graphs,&graphFormat);
%rmPathFiles(/covid_analysis/SAS_V2/graphs/,html);

/********************************************************************/
/***** Plot Regions and states	 								*****/
/********************************************************************/
ods html close;ods rtf close;ods pdf close;ods document close;
options orientation=landscape papersize=tabloid  nomprint nomlogic;
ods graphics on / reset width=16in height=10in imagemap outputfmt=&graphFormat imagefmt=&graphFormat; 
/* Prep and print PDF title */ %InsertPDFReportHeader;

ods html5 file="&outputpath./AllStatesAndCountries.html" gpath= "&outputpath./graphs/" (URL='graphs/') device=&graphFormat; *options(svg_mode="inline");
/* Countries */ %plotNations(	maxplots=30,stplot=Y);
/* States */ 	%plotUSStates(	maxplots=30,stplot=Y,minconf=5000,mindeath=200,xvalues=(5000 to 60000 by 5000),	yvalues=(200 to 4200 by 1000));
/* CBSAs */		%plotCBSAs(	  	maxplots=30,stplot=Y minconf=3000,mindeath=200,xvalues=(5000 to 50000 by 5000), 	yvalues=(200 to 3200 by 1000));
ods html5 close; ods pdf close;

