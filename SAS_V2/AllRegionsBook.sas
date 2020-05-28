/********************************************************************/
/***** ALLStates.sas - Run through all the graphs from load-plot*****/
/********************************************************************/

%let rc = %sysfunc(dlgcdir("/covid_analysis/SAS_V2/")); 
%let mlv = no;
%include "MACROS.sas";
%let graphFormat=png;

/********************************************************************/
/***** Update the JHU data from git site and run data load		*****/
/********************************************************************/

%include "LoadTimeseries.sas";

/********************************************************************/
/***** Clean up the old html and graphs						 	*****/
/********************************************************************/

/* %rmPathFiles(/covid_analysis/SAS_V2/graphs/graphs,&graphFormat); */
/* %rmPathFiles(/covid_analysis/SAS_V2/graphs/,html); */
/* %rmPathFiles(/covid_analysis/SAS_V2/graphs/,pdf); */

/********************************************************************/
/***** Plot Regions and states	 								*****/
/********************************************************************/
ods html close;ods rtf close;ods pdf close;ods document close;
options orientation=landscape papersize=tabloid  nomprint nomlogic;
ods graphics on / reset width=36in height=10in imagemap outputfmt=&graphFormat imagefmt=&graphFormat; 
/* Prep and print PDF title */ %InsertPDFReportHeader(style=styles.htmlblue);

/* ods html5 file="&outputpath./AllStatesAndCountries.html" gpath= "&outputpath./graphs/" (URL='graphs/') device=&graphFormat; *options(svg_mode="inline"); */
/* Countries */ 
option &mlv.mlogic &mlv.mprint;
/* special report */
%let overallplotdays=90;
	%plotstate(state="Iran",level=global,numback=&overallplotdays); 
	
	%plotstate(state="Georgia",level=state,numback=&overallplotdays); 
	%plotstate(state="Atlanta-Sandy Springs-Alpharetta, GA",level=cbsa,numback=&overallplotdays); 
	%plotstate(state="Gainesville, GA",level=cbsa,numback=&overallplotdays); 
	%plotstate(state="South Carolina",level=state,numback=&overallplotdays); 
	%plotstate(state="Greenville-Anderson, SC",level=cbsa,numback=&overallplotdays);
	%plotstate(state="Charleston-North Charleston, SC",level=cbsa,numback=&overallplotdays);
	%plotstate(state="Columbia, SC",level=cbsa,numback=&overallplotdays);
	%plotstate(state="New York-Newark-Jersey City, NY-NJ-PA",level=cbsa,numback=&overallplotdays);
	%plotstate(state="Orlando-Kissimmee-Sanford, FL",level=cbsa,numback=&overallplotdays);
	%plotstate(state="San Antonio-New Braunfels, TX",level=cbsa,numback=&overallplotdays);
	%plotstate(state="Germany",level=global,numback=&overallplotdays);
	%plotstate(state="US",level=global,numback=&overallplotdays);
	%plotstate(state="Brazil",level=global,numback=&overallplotdays);
	%plotstate(state="Russia",level=global,numback=&overallplotdays);
	
	%plotstate(state="Sweden",level=global,numback=&overallplotdays);
/* National */
	%plotNationTrajectory(sortkey=Confirmed,sortdir=descending,maxplots=30,stplot=Y,minconf=1,mindeath=1,xvalues=(1000 to 1301000 by 100000),yvalues=(300 to 80300 by 20000));
	%plotNationTrajectory(sortkey=dif,maxplots=30,stplot=Y,minconf=100,mindeath=1,xvalues=(100 5000 10000 15000  20000 to 220000 by 20000),yvalues=(1 500 1000 5000 10000 to 30000 by 10000));
	%plotpaths(global,location,title=Nations,maxplots=-20);
	%plot_emerging(dif,global,location,sortdir=descending,maxplots=25);

/* States */ 	
	%plotUSTrajectory(sortkey=Confirmed,sortdir=descending,maxplots=30,numback=14,minconf=1000,mindeath=25,xvalues=( 1000 10000 100000 to 400000 by 100000),yvalues=( 100 1000 10000 to 31000 by 10000));
	%plotUSTrajectory(sortkey=dif,maxplots=30,stplot=Y,minconf=5000,mindeath=100,xvalues=(1000 to 70000 by 5000),	yvalues=(100 to 4800 by 1000));
	%plotpaths(state,province_state,title=US States,maxplots=0);
	%plotpaths(state,province_state,title=US States,maxplots=10);
	%plot_emerging(dif,state,province_state,sortdir=descending,maxplots=25);

/* CBSAs */		
	%plotCBSATrajectory(sortkey=confirmed,sortdir=descending,maxplots=30,numback=14, minconf=1000,mindeath=1,xvalues=(1000 10000 100000 to 500000 by 100000),yvalues=(10 100 1000 10000 to 60000 by 10000));	
	%plotCBSATrajectory(sortkey=dif,maxplots=30,stplot=Y, minconf=10,mindeath=1,xvalues=(100 1000 10000 to 100000 by 10000), yvalues=(1 10 100 1000 to 10000 by 1000));	
	%plotpaths(cbsa,cbsa_title,title=US CBSAs,maxplots=25);
	%plot_emerging(dif,cbsa,cbsa_title,sortdir=descending,maxplots=25);

/* ods html5 close;  */
ods pdf close;





/* data  WORK.GLOBAL_TRAJECTORIES; set  WORK.GLOBAL_TRAJECTORIES; */
/* 	if location ~= */
/* 	%plotstate(state="Germany",level=global,numback=&overallplotdays); */
/* 	%plotstate(state="US",level=global,numback=&overallplotdays); */
/* 	%plotstate(state="Brazil",level=global,numback=&overallplotdays); */
/* 	%plotstate(state="Russia",level=global,numback=&overallplotdays); */


ods html close;ods rtf close;ods pdf close;ods document close;
options orientation=landscape papersize=tabloid  nomprint nomlogic;
ods graphics on / reset width=16in height=10in imagemap outputfmt=&graphFormat imagefmt=&graphFormat; 
/* %CountyPlot(SC); */
%CountyPlot(GA);

%CountyPlot(TX);
/* %CountyPlot(FL); */