%let codepath=/repositories/covid19_analysis/SAS_V2/Demonstration;
%let rc = %sysfunc(dlgcdir("&codepath")); 
%include 'MACROS.sas';
libname pCovid '/repositories/covid19_analysis/SAS_V2/data';
options papersize=legal orientation=landscape nosymbolgen nomlogic nomprint;

/***************************************************************************************/
/* %let dataset		=GL_Daily; */
/* %let targetvector	=('US','UK','Germany','Russia','Brazil','India','Mexico'); */
/* %let targetfield	=country_region; */

/***************************************************************************************/
%let dataset		=US_Daily;
%let targetvector	=('South Carolina','North Carolina','Florida','Texas','Tennessee'
,'New York','Massachusetts','California','Illinois');
%let targetfield	=province_state;
/***************************************************************************************/
data _null_;
	call symputx('begindate',intnx('day',date(),-90));
	call symput("wordDte",trim(left(put("&sysdate9"d, worddatx32.))));
run;
%put begindate=&begindate;

proc sql noprint;
	create table _graph as	
		select reportdate
			,&targetfield
			,int(sum(sum(dailyconfirmed,0))) as dailyconfirmed format=comma12.
			,int(sum(sum(dailydeaths,0))) as dailydeaths format=comma12.
			,int(sum(sum(confirmed,0))) as confirmed format=comma12.
			,int(sum(sum(deaths,0))) as deaths format=comma12.
			,int(sum(sum(ma7_cases,0))) as ma7_cases format=comma12.
			,int(sum(sum(ma7_deaths,0))) as ma7_deaths format=comma12.
			,sum(population) as population format=comma12. label='Population'
			,int(sum(sum(ma7_deaths,0)))/int(sum(sum(ma7_cases,0))) as empirical_ma7_death_rate format=percent6.3
			,int(sum(sum(ma7_cases,0)))/sum(population)*1e5 as cases_ma7_per100k format=comma12.3
			,int(sum(sum(ma7_deaths,0)))/sum(population)*1e5 as deaths_ma7_per100k format=comma12.3
			,put(reportdate,DOWNAME3.) as fd_weekday
		from pcovid.&dataset
		where &targetfield in &targetvector
			and reportdate>=&begindate
		group by &targetfield
		,reportdate
		order by &targetfield
		,reportdate
		;
	select min(reportdate) into :minreportdate from _graph;
	select max(reportdate) into :maxreportdate from _graph;
	
quit;
data _graph; set _graph;
	by &targetfield reportdate;
	if last.&targetfield then do;
		plotlabel=&targetfield;
	end;
run;

ods graphics on / reset width=13.5in height=8in imagemap outputfmt=svg imagefmt=svg; 

title 	  "Death Rates Over Time";
title2 	  h=.95 "Updated &wordDte";
footnote1 j=c h=1 "Beware of drawing conclusions from this data beyond the purpose for which it was generated.";
footnote2 j=c h=.95 "Data Source: Johns Hopkins University - https://github.com/CSSEGISandData/COVID-19 Data Updated: &sysdate";
footnote3 j=r h=0.5  "Samuel T. Croker - &sysdate9";
proc sgplot data=_graph ;
	series x=reportdate y=empirical_ma7_death_rate /
		smoothconnect group=&targetfield datalabel=plotlabel 
		lineattrs=(pattern=solid thickness=2) 
		colormodel=(darkred darkblue darkgreen darkcyan darkviolet) 
		tip=(&targetfield empirical_ma7_death_rate  cases_ma7_per100k  deaths_ma7_per100k dailyconfirmed dailydeaths)
		tiplabel=('Location' 'Empirical Death Rate (MA7)' 'Cases p.100k (MA7)' 'Deaths p.100k (MA7)' 'Raw Cases' 'Raw Deaths');
	yaxis grid label="Empirical Estimated Death Rate";
	xaxis min=&begindate label="Report Date" ;
run;
quit;


