
%macro LoadRaw_Legacy(loaddate);
	filename newdata "/covid_analysis/data/Georgia/ga_covid_data_&loaddate./countycases.csv";
	data covidGA.newdata;
		infile newdata dlm=',' dsd firstobs=2 end=eof;
		informat filedate 			8.
				 county_resident 	$50.
				 Population  		8.
				 Positive 			
				 Deaths 			
				 hospitalization 	
				 ;
		format   filedate 			mmddyy8.
				 county_resident 	$50.
				 Population 		comma12.
				 Positive 			comma12.
				 Deaths				comma12.
				 hospitalization	comma12.
				 ;
		label    filedate			="File Date"
				 county_resident 	="County"
				 Population 		="Population"
				 Positive 			="Cases"
				 Deaths				="Deaths"
				 hospitalization	="Hospitalizations"
				 ;
			
		input 
			county_resident $ 
			population 
			positive 
			deaths 
			hospitalization
			;
		filedate=input("&loaddate",yymmdd10.);
		if eof then call symput("filedate",cats("GA",put(filedate,yymmdd6.)));
	run;
	filename newdata clear;
	proc datasets library=covidGA;
		change newdata=&filedate;
	run;
%mend LoadRaw_Legacy;

options mprint mlogic;
libname covidGA "/covid_analysis/data/Georgia";
%loadraw_legacy(2020-05-02);
%loadraw_legacy(2020-05-03);
%loadraw_legacy(2020-05-04);

data covidga.GA_Data;
	set  COVIDGA.GA200502  COVIDGA.GA200503  COVIDGA.GA200504;
run;


proc sql noprint;
	create table _plot as	
		select 
			 filedate
			,sum(population)  	as total_population
			,sum(positive) 		as total_positive
			,sum(deaths)			as total_deaths
			,sum(hospitalization) as total_hospitalized
		from covidga.ga_data 
		group by filedate
		order by filedate;
	;
quit;	
	
	
	