/********************************************************************/
/***** ALLStates.sas - Run through all the graphs from load-plot*****/
/********************************************************************/

%let rc = %sysfunc(dlgcdir("/covid_analysis/SAS_V2/")); 
%include "LoadTimeseries.sas";
%let graphFormat=png;

/* *You will need to rerun part of loadtimeseries.sas after this; */
/* proc sql;  */
/* 	insert into US_AUGMENTEd  */
/* 			(province_state, filedate, confirmed, deaths)  */
/* 		values("Georgia", '20APR2020'd,19399,775) */
/* 	; */
/* quit; */

/* %create_trajectories; */

proc sql;
	select distinct cbsa_title from cbsa_trajectories 
	where lowcase(cbsa_title) contains "new york";
quit;
proc print data=state_trajectories;
	where province_state='Georgia';
	var filedate confirmed dif1_confirmed ma7_new_confirmed ma7_confirmed ;
run;

/********************************************************************/
/***** Plot a single state group - just change the macvar here 	*****/
/********************************************************************/

%rmPathFiles(/covid_analysis/SAS_V2/graphs/graphs,&graphFormat);
%rmPathFiles(/covid_analysis/SAS_V2/graphs/,html);

/* CBSAs */
%plotstate(state=%str(Atlanta-Sandy Springs-Alpharetta, GA),level=cbsa,plotback=30,gfmt=&graphFormat);
%plotstate(state=%str(San Antonio-New Braunfels, TX),level=cbsa,plotback=30,gfmt=&graphFormat);
%plotstate(state=%str(Albany, GA),level=cbsa,plotback=30,gfmt=&graphFormat);
%plotstate(state=%str(Charleston-North Charleston, SC),level=cbsa,plotback=30,gfmt=&graphFormat);
%plotstate(state=%str(New York-Newark-Jersey City, NY-NJ-PA),level=cbsa,plotback=30,gfmt=&graphFormat);

/* States */
/* %plotstate(state=Georgia,level=state,plotback=30,gfmt=&graphFormat); */

%plotstate(state=all,level=state,plotback=30,gfmt=&graphFormat);

/* Countries */
%plotstate(state=US,level=global,plotback=30,gfmt=&graphFormat);
%plotstate(state=Italy,level=global,plotback=30,gfmt=&graphFormat);
%plotstate(state=Germany,level=global,plotback=30,gfmt=&graphFormat);
%plotstate(state=United Kingdom,level=global,plotback=30,gfmt=&graphFormat);
%plotstate(state=Russia,level=global,plotback=30,gfmt=&graphFormat);
%plotstate(state=India,level=global,plotback=30,gfmt=&graphFormat);

%plotstate(state=Mexico,level=global,plotback=30,gfmt=&graphFormat);
%plotstate(state=Brazil,level=global,plotback=30,gfmt=&graphFormat);


/********************************************************************/
/***** Plot ALL states			 								*****/
/********************************************************************/
/* options orientation=landscape papersize=(7.5in 5in) ; */
/* ods graphics on /  width=7.5in height=5in  imagemap outputfmt=svg ; */
/* ods html5 close; ods html close; ODS Listing close; */
/* ODS HTML gpath="&outputpath/graphs"(URL='graphs/')  */
/* 		 path="&outputpath"(URL=NONE) */
/* 		 contents="contents.html" */
/* 		 frame="AllStates_Individual.html" */
/* 		 body="body.html" */
/* 		  */
/* 		 device=svg; */
/*  */
/* %plotstate; */
/* ods html close; */

/********************************************************************/
/***** 				Plot FIPS Trajectories						*****/
/********************************************************************/
%let daysback=30;
%let minconf=2000;
%let mindeath=200;
%let yvals=(200 to 1200 by 200);
%let plottip=combined_key FIPS  filedate confirmed deaths;
%let plottiplab="Location" "FIPS" "FileDate" "Confirmed" "Deaths";
	

proc rank data=fips_trajectories(where=(plotseq=1)) out=_fipsranks groups=10 ties=dense;
	var casepercapita caseperbed caseperhospital;
	ranks casepercapita_rank caseperbed_rank caseperhospital_rank;
run;
proc sql;
	create table _plots as 
		select a.*
		,casepercapita_rank
		,caseperbed_rank
		,caseperhospital_rank
		from fips_trajectories a left join _fipsranks b
		on a.fips=b.fips
		order by fips, filedate;
quit;
proc datasets lib=work;
	modify _plots;
		label casepercapita 	= "Case per Capita"
			  caseperbed 		= "Case per ICU Bed"
			  caseperhospital	= "Case per Hospital";
		format 
			  casepercapita   comma12.6
			  caseperbed 	  comma12.6	
			  caseperhospital comma12.6;
quit;
	
options orientation=landscape papersize=(12in 12in) ;
	ods graphics on / reset width=12in height=12in  imagemap imagename="AllFIPS" outputfmt=&graphFormat ;
	ods html close;ods rtf close;ods pdf close;ods document close;

ods html5 file="&outputpath./AllFIPS.html" 
		gpath= "&outputpath." 
		device=svg 
		options(svg_mode="inline");
	title US FIPS SARS-CoV-2 Trajectories;
	title2 h=0.95 "New York 36061 Removed";
	footnote   h=1 "Data Source: Johns Hopkins University - https://github.com/CSSEGISandData/SARS-CoV-2  Data Updated: &sysdate";
	footnote2  h=1 "Showing the Last &daysback Days";
	footnote3  h=0.5 justify=right "Samuel T. Croker - &sysdate9";
	ods proclabel " "; 
proc sgplot 
	data=fips_trajectories(where=(fips~='36061' and plotseq<=&daysback and confirmed>&minconf and deaths>&mindeath))
	noautolegend;
	scatter x=Confirmed y=Deaths / group=fips 
		datalabel=combined_key 
		markerattrs=(size=7) 
		datalabelattrs=(size=5) 
		transparency=0.25
		tip=(&plottip) tiplabel=(&plottiplab) ;
	series x=Confirmed y=Deaths  / group=fips ;
	xaxis grid minor minorgrid type=log values=(2000 to 30000 by 2000)  LOGSTYLE=logexpand  fitpolicy=rotatethin ;
	yaxis grid minor minorgrid type=log values=&yvals LOGSTYLE=logexpand  fitpolicy=thin ;
run;

	title US FIPS SARS-CoV-2 Trajectories Cases Per Capita;
	title2 h=0.95 "New York 36061 Removed";
	footnote   h=1 "Data Source: Johns Hopkins University - https://github.com/CSSEGISandData/SARS-CoV-2  Data Updated: &sysdate";
	footnote2  h=1 "Showing the Last &daysback Days";
	footnote3  h=0.5 justify=right "Samuel T. Croker - &sysdate9";
	ods proclabel " "; 
proc sgplot 
	data=_plots(where=(fips~='36061' and plotseq<=&daysback and casepercapita_rank >= 7 and deaths>&mindeath))
	noautolegend;
	scatter x=casepercapita y=Deaths / group=fips 
		datalabel=combined_key 
		markerattrs=(size=7) 
		datalabelattrs=(size=5) 
		transparency=0.25
		tip=(&plottip) tiplabel=(&plottiplab) ;
	series x=casepercapita y=Deaths  / group=fips ;
	xaxis grid minor minorgrid type=log LOGSTYLE=logexpand  fitpolicy=rotatethin ;
	yaxis grid minor minorgrid values=&yvals type=log LOGSTYLE=logexpand  fitpolicy=thin ;
run;
	title US FIPS SARS-CoV-2 Trajectories Cases Per Hospital;
	title2 h=0.95 "New York 36061 Removed";
	footnote   h=1 "Data Source: Johns Hopkins University - https://github.com/CSSEGISandData/SARS-CoV-2  Data Updated: &sysdate";
	footnote2  h=1 "Showing the Last &daysback Days";
	footnote3  h=0.5 justify=right "Samuel T. Croker - &sysdate9";
	ods proclabel " "; 
proc sgplot 
	data=_plots(where=(fips~='36061' and plotseq<=&daysback and caseperhospital_rank >= 7 and deaths>&mindeath))
	noautolegend;
	scatter x=caseperhospital y=Deaths / group=fips 
		datalabel=combined_key 
		markerattrs=(size=7) 
		datalabelattrs=(size=5) 
		transparency=0.25
		tip=(&plottip) tiplabel=(&plottiplab) ;
	series x=caseperhospital y=Deaths  / group=fips ;
	xaxis grid minor minorgrid type=log LOGSTYLE=logexpand  fitpolicy=rotatethin ;
	yaxis grid minor minorgrid values=&yvals type=log LOGSTYLE=logexpand  fitpolicy=thin ;
run;
	title US FIPS SARS-CoV-2 Trajectories Cases Per ICU Bed;
	title2 h=0.95 "New York 36061 Removed";
	footnote   h=1 "Data Source: Johns Hopkins University - https://github.com/CSSEGISandData/SARS-CoV-2  Data Updated: &sysdate";
	footnote2  h=1 "Showing the Last &daysback Days";
	footnote3  h=0.5 justify=right "Samuel T. Croker - &sysdate9";
	ods proclabel " "; 
proc sgplot 
	data=_plots(where=(fips~='36061' and plotseq<=&daysback and caseperbed_rank >= 7 and deaths>&mindeath))
	noautolegend;
	scatter x=caseperBed y=Deaths / group=fips 
		datalabel=combined_key 
		markerattrs=(size=7) 
		datalabelattrs=(size=5) 
		transparency=0.25
		tip=(&plottip) tiplabel=(&plottiplab) ;
	series x=caseperbed y=Deaths  / group=fips ;
	xaxis grid minor minorgrid type=log LOGSTYLE=logexpand  fitpolicy=rotatethin ;
	yaxis grid minor minorgrid values=&yvals type=log LOGSTYLE=logexpand  fitpolicy=thin ;
run;
ods html5 close;

proc datasets lib=work nolist; delete _plots _fipsranks; quit;




/********************************************************************/
/***** 				Plot CBSA Trajectories						*****/
/********************************************************************/
%let daysback=15;
%let minconf=2000;
%let mindeath=200;
%let yvals=(200 to 2000 by 200);
%let plottip=cbsa_title filedate confirmed deaths;
%let plottiplab="CBSA" "FileDate" "Confirmed" "Deaths";
	

proc rank data=cbsa_trajectories(where=(plotseq=1)) out=_cbsaranks groups=10 ties=dense;
	var casepercapita caseperbed caseperhospital;
	ranks casepercapita_rank caseperbed_rank caseperhospital_rank;
run;
proc sql;
	create table _plots as 
		select a.*, casepercapita_rank, caseperbed_rank, caseperhospital_rank
		from cbsa_trajectories a left join _cbsaranks b
		on a.cbsa_title=b.cbsa_title
		order by cbsa_title, filedate;
quit;	
proc datasets lib=work;
	modify _plots;
		label casepercapita 	= "Case per Capita"
			  caseperbed 		= "Case per ICU Bed"
			  caseperhospital	= "Case per Hospital";
		format 
			  casepercapita   comma12.6
			  caseperbed 	  comma12.6	
			  caseperhospital comma12.6;
quit;
	
options orientation=landscape papersize=(12in 12in) ;
	ods graphics on / reset width=12in height=12in  imagemap imagename="AllCBSA" outputfmt=&graphFormat ;
	ods html close;ods rtf close;ods pdf close;ods document close;

ods html5 file="&outputpath./AllCBSA.html" 
		gpath= "&outputpath." 
		device=&graphFormat 
		options(svg_mode="inline");
	title US CBSA SARS-CoV-2 Trajectories;
	title2 h=0.95 "Removed: New York-Newark-Jersey City, NY-NJ-PA";
	footnote   h=1 "Data Source: Johns Hopkins University - https://github.com/CSSEGISandData/SARS-CoV-2  Data Updated: &sysdate";
	footnote2  h=1 "Showing the Last &daysback Days";
	footnote3  h=0.5 justify=right "Samuel T. Croker - &sysdate9";

proc sgplot 
	data=cbsa_trajectories(where=(cbsa_title ~= "New York-Newark-Jersey City, NY-NJ-PA" and plotseq<=&daysback and confirmed>&minconf and deaths>&mindeath))
	noautolegend;
	ods proclabel " "; 
	scatter x=Confirmed y=Deaths / group=cbsa_title 
		datalabel=cbsa_title  
		markerattrs=(size=7) 
		datalabelattrs=(size=5) 
		transparency=0.25
		tip=(&plottip) tiplabel=(&plottiplab) ;
	series x=Confirmed y=Deaths  / group=cbsa_title ;
	xaxis grid minor minorgrid values=(2500 to 30000 by 5000)type=log min=&minconf  LOGSTYLE=logexpand ;
	yaxis grid minor minorgrid values=&yvals type=log min=&mindeath LOGSTYLE=LOGEXPAND ;
run;


title US CBSA SARS-CoV-2 Trajectories Per Capita;
footnote   h=1 "Data Source: Johns Hopkins University - https://github.com/CSSEGISandData/SARS-CoV-2  Data Updated: &sysdate";
footnote2  h=1 "Showing the Last &daysback Days";
footnote3  h=0.5 justify=right "Samuel T. Croker - &sysdate9";

proc sgplot 
	data=_plots(where=( plotseq<=&daysback and confirmed>&minconf and deaths>&mindeath))
	noautolegend;
	ods proclabel " "; 
	scatter x=CasePerCapita y=Deaths / group=cbsa_title 
		datalabel=cbsa_title  
		markerattrs=(size=7) 
		datalabelattrs=(size=5) 
		transparency=0.25
		tip=(&plottip) tiplabel=(&plottiplab) ;
	series x=CasePerCapita y=Deaths  / group=cbsa_title ;
	xaxis grid minor minorgrid type=log  LOGSTYLE=logexpand ;
	yaxis grid minor values=&yvals minorgrid type=log  LOGSTYLE=LOGEXPAND ;
run;

title US CBSA SARS-CoV-2 Trajectories Per Hospital;
footnote   h=1 "Data Source: Johns Hopkins University - https://github.com/CSSEGISandData/SARS-CoV-2  Data Updated: &sysdate";
footnote2  h=1 "Showing the Last &daysback Days";
footnote3  h=0.5 justify=right "Samuel T. Croker - &sysdate9";

proc sgplot 
	data=_plots(where=( plotseq<=&daysback and confirmed>&minconf and deaths>&mindeath))
	noautolegend;
	ods proclabel " "; 
	scatter x=CasePerhospital y=Deaths / group=cbsa_title 
		datalabel=cbsa_title  
		markerattrs=(size=7) 
		datalabelattrs=(size=5) 
		transparency=0.25
		tip=(&plottip) tiplabel=(&plottiplab) ;
	series x=CasePerhospital y=Deaths  / group=cbsa_title ;
	xaxis grid minor minorgrid type=log  LOGSTYLE=logexpand ;
	yaxis grid minor values=&yvals minorgrid type=log  LOGSTYLE=LOGEXPAND ;
run;

title US CBSA SARS-CoV-2 Trajectories Per ICU Bed;
footnote   h=1 "Data Source: Johns Hopkins University - https://github.com/CSSEGISandData/SARS-CoV-2  Data Updated: &sysdate";
footnote2  h=1 "Showing the Last &daysback Days";
footnote3  h=0.5 justify=right "Samuel T. Croker - &sysdate9";

proc sgplot 
	data=_plots(where=( plotseq<=&daysback and confirmed>&minconf and deaths>&mindeath))
	noautolegend;
	ods proclabel " "; 
	scatter x=CasePerbed y=Deaths / group=cbsa_title 
		datalabel=cbsa_title  
		markerattrs=(size=7) 
		datalabelattrs=(size=5) 
		transparency=0.25
		tip=(&plottip) tiplabel=(&plottiplab) ;
	series x=CasePerbed y=Deaths  / group=cbsa_title ;
	xaxis grid type=log  LOGSTYLE=logexpand ;
	yaxis grid type=log  LOGSTYLE=LOGEXPAND ;
run;
ods html5 close;


proc datasets library=work nolist; delete _plots _cbsaranks; quit;

/********************************************************************/
/***** Plot State Trajectories	 								*****/
/********************************************************************/
%let daysback=14;
%let minconf=5000;
%let mindeath=200;
%let yvals=(200 to 1200 by 200);
%let plottip=province_state filedate confirmed deaths;
%let plottiplab="State" "FileDate" "Confirmed" "Deaths";


options orientation=landscape papersize=(12in 12in) ;
	ods graphics on / reset width=12in height=12in  imagemap imagename="AllStates" outputfmt=&graphFormat ;
	ods html close;ods rtf close;ods pdf close;ods document close;
ods html5 file="AllStates.html" 
		 gpath="&outputpath/graphs"(URL='graphs/') 
		  path="&outputpath"(URL=NONE)
		device=&graphFormat 
		options(svg_mode="inline") 
		;
	title h=2 US State SARS-CoV-2 Trajectories;
	title2 h=1.5 "Removed: New York, New Jersey";
	footnote   h=1.5 "Data Source: Johns Hopkins University - https://github.com/CSSEGISandData/SARS-CoV-2  Data Updated: &sysdate";
	footnote2  h=1.5 "Showing the Last &daysback Days";
	footnote3  h=0.9 justify=right "Samuel T. Croker - &sysdate9";
	ods proclabel " "; 
proc sgplot 
	data=state_trajectories(where=(province_state not in ("New York" "New Jersey") and plotseq<=&daysback and confirmed>&minconf and deaths>&mindeath))
	noautolegend;
	scatter x=Confirmed y=Deaths / group=province_state 
		datalabel=province_state
		markerattrs=(size=12) 
		datalabelattrs=(size=12) 
		transparency=0.25
		tip=(&plottip) tiplabel=(&plottiplab) ;
	series x=Confirmed y=Deaths  / group=province_state;
	xaxis grid minor minorgrid type=log min=&minconf  labelattrs=(size=15) valueattrs=(size=12) LOGSTYLE=LOGEXPAND values = (5000 to 40000 by 5000);
	yaxis grid minor minorgrid type=log min=&mindeath labelattrs=(size=15) valueattrs=(size=12) LOGSTYLE=LOGEXPAND values = (200 500 1000 1500 2000 2500 ) ;
run;
ods html5 close;


/********************************************************************/
/***** 				Plot Global Trajectories	 				*****/
/********************************************************************/
%let daysback=14;
%let minconf=1000;
%let mindeath=100;
options orientation=landscape papersize=(12in 12in) ;
	ods graphics on / reset width=12in height=12in  imagemap imagename="AllNations" outputfmt=&graphFormat ;
	ods html close;ods rtf close;ods pdf close;ods document close;

%let plottip=country_region location filedate confirmed deaths;
%let plottiplab="Country" "Location" "FileDate" "Confirmed" "Deaths";

ods html5 file="&outputpath./AllCountries.html" 
		gpath= "&outputpath." 
		device=svg 
		options(svg_mode="inline");
	title Global National Trajectories;
	footnote   h=1 "Data Source: Johns Hopkins University - https://github.com/CSSEGISandData/SARS-CoV-2  Data Updated: &sysdate";
	footnote2  h=1 "Showing the Last &daysback Days";
	footnote3  justify=right  height=0.5 "Samuel T. Croker - &sysdate9";
	ods proclabel " "; 
proc sgplot 
	data=global_trajectories(where=(plotseq<=&daysback and confirmed>&minconf and deaths>&mindeath))
	noautolegend;
	scatter x=Confirmed y=Deaths / group=location
		datalabel=location
		markerattrs=(size=7) 
		datalabelattrs=(size=5) 
		transparency=0.25
		tip=(&plottip) tiplabel=(&plottiplab) ;
	series x=Confirmed y=Deaths  / group=location
		tip=(&plottip) tiplabel=(&plottiplab) ;
	xaxis grid minor minorgrid type=log min=&minconf max=600000 LOGSTYLE=linear;* values=(1000 0 to 600000 by 100000);
	yaxis grid minor minorgrid type=log min=&mindeath LOGSTYLE=linear;* values=(1000 to 26000 by 5000);
run;
ods html5 close;



/********************************************************************/
/***** 			 								*****/
/********************************************************************/













