/********************************************************************/
/***** ALLStates.sas - Run through all the graphs from load-plot*****/
/********************************************************************/

%let rc = %sysfunc(dlgcdir("/covid_analysis/SAS_V2/")); 
%include "MACROS.sas";
%let graphFormat=png;
 
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
%rmPathFiles(/covid_analysis/SAS_V2/graphs/,pdf);

/********************************************************************/
/***** Plot Regions and states	 								*****/
/********************************************************************/
ods html close;ods rtf close;ods pdf close;ods document close;
options orientation=landscape papersize=tabloid  nomprint nomlogic;
ods graphics on / reset width=16in height=10in imagemap outputfmt=&graphFormat imagefmt=&graphFormat; 
/* Prep and print PDF title */ %InsertPDFReportHeader(style=styles.htmlblue);

/* ods html5 file="&outputpath./AllStatesAndCountries.html" gpath= "&outputpath./graphs/" (URL='graphs/') device=&graphFormat; *options(svg_mode="inline"); */
/* Countries */ 
options nomprint nomlogic;
/* special report */
	%plotstate(state="Georgia",level=state,numback=30); 
	%plotstate(state="Atlanta-Sandy Springs-Alpharetta, GA",level=cbsa,numback=30); 
	%plotstate(state="South Carolina",level=state,numback=30); 
	%plotstate(state="Greenville-Anderson, SC",level=cbsa,numback=30); 
/* National */
	%plotNationTrajectory(sortkey=Confirmed,sortdir=descending,maxplots=30,stplot=Y,minconf=1,mindeath=1,xvalues=(1000 to 1301000 by 100000),yvalues=(300 to 80300 by 20000));
	%plotNationTrajectory(sortkey=dif,maxplots=30,stplot=Y,minconf=100,mindeath=1,xvalues=(100 5000 10000 15000  20000 to 220000 by 20000),yvalues=(1 500 1000 5000 10000 to 30000 by 10000));
	%plotpaths(global,location,title=Nations,maxplots=-20);
	%plot_emerging(dif,global,location,sortdir=descending);

/* States */ 	
	%plotUSTrajectory(sortkey=Confirmed,sortdir=descending,maxplots=30,numback=14,minconf=1000,mindeath=25,xvalues=( 1000 10000 100000 to 400000 by 100000),yvalues=( 100 1000 10000 to 31000 by 10000));
	%plotUSTrajectory(sortkey=dif,maxplots=30,stplot=Y,minconf=5000,mindeath=200,xvalues=(1000 to 70000 by 5000),	yvalues=(200 to 4800 by 1000));
	%plotpaths(state,province_state,title=US States,maxplots=0);
	%plotpaths(state,province_state,title=US States,maxplots=10);
	%plot_emerging(dif,state,province_state,sortdir=descending);

/* CBSAs */		
	%plotCBSATrajectory(sortkey=confirmed,sortdir=descending,maxplots=30,numback=14, minconf=1000,mindeath=1,xvalues=(1000 10000 100000 to 500000 by 100000),yvalues=(10 100 1000 10000 to 60000 by 10000));	
	%plotCBSATrajectory(sortkey=dif,maxplots=30,stplot=Y, minconf=10,mindeath=1,xvalues=(100 1000 10000 to 100000 by 10000), yvalues=(1 10 100 1000 to 10000 by 1000));	
	%plotpaths(cbsa,cbsa_title,title=US CBSAs,maxplots=25);
	%plot_emerging(dif,cbsa,cbsa_title,sortdir=descending);

/* ods html5 close;  */
ods pdf close;



