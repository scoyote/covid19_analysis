/********************************************************************/
/***** ALLStates.sas - Run through all the graphs from load-plot*****/
/********************************************************************/

%let rc = %sysfunc(dlgcdir("/covid_analysis/SAS_V2/")); 
%let mlv = no;
%include "MACROS.sas";
%let graphFormat=svg;

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
ods graphics on / reset width=16in height=10in imagemap outputfmt=&graphFormat imagefmt=&graphFormat; 
/* Prep and print PDF title */ %InsertPDFReportHeader(style=styles.htmlblue);

/* ods html5 file="&outputpath./AllStatesAndCountries.html" gpath= "&outputpath./graphs/" (URL='graphs/') device=&graphFormat; *options(svg_mode="inline"); */
/* Countries */ 
option &mlv.mlogic &mlv.mprint;
/* special report */
/* proc sql; select distinct cbsa_title from cbsa_trajectories where cbsa_title contains "FL"; quit; */

%let overallplotdays=92;
	%plotstate(state="Georgia",level=state,numback=&overallplotdays); 
	%plotstate(state="Atlanta-Sandy Springs-Alpharetta, GA",level=cbsa,numback=&overallplotdays); 

	%plotstate(state="South Carolina",level=state,numback=&overallplotdays); 
	%plotstate(state="Greenville-Anderson, SC",level=cbsa,numback=&overallplotdays);
	
/* 	%plotstate(state="Ohio",level=state,numback=&overallplotdays); */
/* 	%plotstate(state="Huntington-Ashland, WV-KY-OH",level=cbsa,numback=&overallplotdays); */
/* 	%plotstate(state="North Carolina",level=state,numback=&overallplotdays);  */
/* 	%plotstate(state="Charlotte-Concord-Gastonia, NC-SC",level=cbsa,numback=&overallplotdays); */
/* 	%plotstate(state="Greensboro-High Point, NC",level=cbsa,numback=&overallplotdays); */
/* 	%plotstate(state="Durham-Chapel Hill, NC",level=cbsa,numback=&overallplotdays); */
	%plotstate(state="San Francisco-Oakland-Berkeley, CA",level=cbsa,numback=&overallplotdays);
	%plotstate(state="New York-Newark-Jersey City, NY-NJ-PA",level=cbsa,numback=&overallplotdays);
	
	%plotstate(state="Florida",level=state,numback=&overallplotdays); 
	%plotstate(state="Orlando-Kissimmee-Sanford, FL",level=cbsa,numback=&overallplotdays);
	%plotstate(state="Miami-Fort Lauderdale-Pompano Beach, FL",level=cbsa,numback=&overallplotdays);

	%plotstate(state="Texas",level=state,numback=&overallplotdays); 
	%plotstate(state="San Antonio-New Braunfels, TX",level=cbsa,numback=&overallplotdays);
		
	%plotstate(state="US",level=global,numback=&overallplotdays);
	%plotstate(state="Germany",level=global,numback=&overallplotdays);
	%plotstate(state="Russia",level=global,numback=&overallplotdays);
	%plotstate(state="India",level=global,numback=&overallplotdays);
	%plotstate(state="Brazil",level=global,numback=&overallplotdays);
	%plotstate(state="Mexico",level=global,numback=&overallplotdays);
	%plotstate(state="Sweden",level=global,numback=&overallplotdays);
/* National */
	%plotNationTrajectory(sortkey=Confirmed,sortdir=descending,maxplots=30,stplot=Y,minconf=1,mindeath=1,xvalues=(0 to 1750000 by 100000),yvalues=(0 to 140000 by 20000));
	%plotNationTrajectory(sortkey=dif,maxplots=30,stplot=Y,minconf=100,mindeath=1,xvalues=(100 1000 to 20000 by 2000 20000 to 700000 by 20000),yvalues=(1 500 1000 5000 10000 to 60000 by 10000));
	%plotpaths(global,location,title=Nations,maxplots=-10);
/* 	%plot_emerging(dif,global,location,sortdir=descending,maxplots=25); */

/* States */ 	
	%plotUSTrajectory(sortkey=Confirmed,sortdir=descending,maxplots=30,numback=14,minconf=1000,mindeath=25,xvalues=(10000 to 100000 by 5000 100000 to 400000 by 50000),yvalues=( 100 to 1000 by 100 1000 to 10000 by 1000 10000 to 40000 by 10000));
	%plotUSTrajectory(sortkey=dif,maxplots=30,stplot=Y,minconf=5000,mindeath=100,xvalues=(5000 to 240000 by 10000),	yvalues=(100 to 10000 by 1000));
	%plotpaths(state,province_state,title=US States,maxplots=-5);
	%plotpaths(state,province_state,title=US States,maxplots=15);
/* 	%plot_emerging(dif,state,province_state,sortdir=descending,maxplots=25); */

/* CBSAs */		
	%plotCBSATrajectory(sortkey=confirmed,sortdir=descending,maxplots=30,numback=14, minconf=1000,mindeath=1,xvalues=(5000 100000 100000 to 500000 by 100000),yvalues=(100 1000 10000 to 60000 by 10000));	
	%plotCBSATrajectory(sortkey=dif,maxplots=30,stplot=Y,numback=30, minconf=10,mindeath=1,xvalues=(100 1000 10000 to 150000 by 20000), yvalues=(1 10 100 1000 to 15000 by 2000));	
	%plotpaths(cbsa,cbsa_title,title=US CBSAs,maxplots=25);
/* 	%plot_emerging(dif,cbsa,cbsa_title,sortdir=descending,maxplots=25); */

/* ods html5 close;  */
ods pdf close;


/* data  WORK.GLOBAL_TRAJECTORIES; set  WORK.GLOBAL_TRAJECTORIES; */
/* 	if location ~= */
/* 	%plotstate(state="Germany",level=global,numback=&overallplotdays); */
/* 	%plotstate(state="US",level=global,numback=&overallplotdays); */
/* 	%plotstate(state="Brazil",level=global,numback=&overallplotdays); */
/* 	%plotstate(state="Russia",level=global,numback=&overallplotdays); */

/*  */
/* ods html close;ods rtf close;ods pdf close;ods document close; */
/* options orientation=landscape papersize=tabloid  nomprint nomlogic; */
/* ods graphics on / reset width=16in height=10in imagemap outputfmt=&graphFormat imagefmt=&graphFormat;  */
/* %CountyPlot(SC); */
/* %CountyPlot(GA); */
/*  */
/* %CountyPlot(NC); */
/* %CountyPlot(TX); */
/* %CountyPlot(FL); */
