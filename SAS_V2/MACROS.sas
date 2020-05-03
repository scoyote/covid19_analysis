 /********************************************************************************************************************************/
/***** MACROS.sas - This macro file is for the second generation of the JHU Covid Plots 									*****/
/********************************************************************************************************************************/


/********************************************************************************************************************************/
/***** Create Colors - Create color dataset to use as attributes in PROC SGPLOT. 											*****/
/********************************************************************************************************************************/

data colormap;                 
	length Value 8. FillColor $30;
	input value FillColor $;
	informat fillcolor $30.; 
	retain ID 'myid'            
	     Show 'AttrMap';  
/* if you add here add the variable to the selects in the 3 macros */
	COLOR		= fillcolor;
	linecolor	= fillcolor;
	MARKERCOLOR	= fillcolor;
	textcolor	= fillcolor;
	MARKERTRANSPARENCY=0.5;
	markersymbol='plus';
	markersize=10;
/* if you add here add the variable to the selects in the 3 macros */
datalines;
1	 red 
2	 green
3	 blue
4	 lilac
5	 black
6	 gray
7	 magenta
8	 orange
9	 steel
10	 violet
11	 vipk
12	 brown
13	 tan
14	 grr
15	 mopr
16	 pav
17	 vliv
18	 vioy
19	 dagry
20	 bibg
21	 vilg
22	 molg
23	 moolg
24	 vig
25	 viro
26	 grro
27	 moppk
28	 grppk
29	 stp
30	 dap
;
run;


/********************************************************************************************************************************/
/***** LOADTS_GLOBAL - Import the global time series, dates in columns, and put it into a single date column. 						*****/
/********************************************************************************************************************************/

%macro loadTS_Global(type=Confirmed); 
	data _null_;
		call symput("ptype", propcase("&type"));
	run;

	FILENAME REFFILE "/covid19data/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_&type._global.csv";

	PROC IMPORT DATAFILE=REFFILE DBMS=CSV OUT=WORK.T_IMPORT_TS;
		GETNAMES=YES;
	RUN;

	proc datasets library=work;
		modify T_IMPORT_TS;
		rename 'Country/Region'n=country_region;
		rename 'Province/State'n=province_state;
		rename lat=latitude;
		rename long=longitude;
	quit;

	data WORK.T_IMPORT_TS;
		length location $100;
		set WORK.T_IMPORT_TS;

		if missing(province_state) then
			location=country_region;
		else
			location=cats(province_state, "-", country_region);
	run;

	/* Roll this up by location so we can use the _numeric_
	shortcut for the dates - this is a very small dataset */
	proc sort data=work.t_import_ts;
		by province_state country_region latitude longitude;
	run;

	proc contents data=t_import_ts out=_cont;
	run;

	proc sql;
		select compress(name) into :txcols separated by '"n "' from _cont where 
			type=1 and name not in ('province_state', 'country_region', 'location', 
			'latitude', 'longitude');
	quit;

	proc transpose data=WORK.T_IMPORT_TS out=&TYPE._TS prefix=UpDate_t;
		var "&txcols"n;
		by province_state country_region location latitude longitude;
	run;

	proc datasets library=work;
		modify &TYPE._TS;
		rename update_t1=&type;
		label &type="&ptype";
		rename _name_=temp_FileDate;
	quit;
	
	/* Convert the string date to a real date */
	data &TYPE._TS;
		set &TYPE._TS;
		FileDate=input(temp_filedate, mmddyy8.);
		format filedate yymmdd10.
			   &type comma12.
			   ;
		label filedate="File Date";
		drop temp_filedate;
	run;

	proc sort data=WORK.&TYPE._TS out=WORK.&type._global_TS;
		by province_state country_region location latitude longitude filedate;
	run;
	proc datasets library=work;
		delete t_import_ts &type._ts _cont;
	quit;

%mend loadTS_global;


/********************************************************************************************************************************/
/***** LOADTS_US - Import the US time series, dates in columns, and put it into a single date column. 							*****/
/********************************************************************************************************************************/

%macro loadTS_US(type=confirmed);
	data _null_;
		call symput("ptype", propcase("&type"));
	run;

	FILENAME REFFILE "/covid19data/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_&type._US.csv";

	PROC IMPORT DATAFILE=REFFILE DBMS=CSV OUT=WORK.T_IMPORT_TS;
		GETNAMES=YES;
	RUN;

	proc sort data=t_import_ts;
		by fips;
	run;

	data t_import_ts;
		informat fipsjoin $5.;
		set t_import_ts;
		by fips;

		/*fix the case of missing fips for the transpose
		to have a single column */
		if missing(fips) then
			do;

				if first.fips then
					a=1;
				else
					a+1;
				fipsjoin=cats("f", a);
			end;
		else
			FIPSJOIN=put(fips, fipsfive.);
		drop a fips;
	run;

	proc datasets library=work;
		modify T_IMPORT_TS;
		rename fipsjoin=fips;
	quit;

	proc sort data=work.t_import_ts;
		by uid fips Combined_Key Country_Region Province_State admin2 code3 iso2 iso3 
			lat long_ %if &type=deaths %then
				%do;
				population %end;
		;
	run;

	proc contents data=t_import_ts out=_cont;
	run;

	proc sql;
		select compress(name) into :txcols separated by '"n "' from _cont where 
			type=1 and upcase(name) not in ('UID', 'POPULATION', 'COMBINED_KEY'
		, 'COUNTRY_REGION', 'PROVINCE_STATE', 'FIPS', 'ADMIN2', 'CODE3', 'ISO2', 
			'ISO3'
		, 'LAT', 'LONG_', );
	quit;

	proc transpose data=WORK.T_IMPORT_TS out=work.&TYPE._TS prefix=UpDate_t;
		var "&txcols"n;
		by uid fips Combined_Key Country_Region Province_State admin2 code3 iso2 iso3 
			lat long_ 
			%if &type=deaths %then
				%do;
				population %end;
		;
	run;

	proc datasets library=work;
		modify &TYPE._TS;
		rename update_t1=&type;
		rename _name_=temp_FileDate;
	quit;

	data &TYPE._TS;
		set &TYPE._TS;
		FileDate=input(temp_filedate, mmddyy8.);
		format filedate yymmdd10.
			   &type comma12.;
		label filedate="File Date";
		drop temp_filedate;
	run;

	proc sort data=WORK.&TYPE._TS out=WORK.&type._US_TS;
		by fips filedate;
	run;
	proc datasets library=work;
		delete t_import_ts &type._ts _cont;
	quit;

%mend loadTS_US;
/********************************************************************************************************************************/
/***** LOADCENSUS Macro - Imports the census file from disk																	*****/
/********************************************************************************************************************************/

%macro LoadCensus;
	/* County to CBSA Crosswalk: Source: https://www.census.gov/programs-surveys/metro-micro/about/delineation-files.html */
	/* https://www2.census.gov/programs-surveys/metro-micro/geographies/reference-files/2018/delineation-files/list1_Sep_2018.xls */
	data fips.CBSA_County_Crosswalk;
		infile "/covid_analysis/data/MSA_CountyFipsCrosswalk.csv" delimiter=',' 
			MISSOVER DSD firstobs=2;
		informat CBSA_Code $234.;
		informat Metropolitan_Division_Code best32.;
		informat CSA_Code best32.;
		informat CBSA_Title $100.;
		informat MSA $100.;
		informat MSA_Title $100.;
		informat CSA_Title $100.;
		informat County_Equivalent $100.;
		informat State_Name $20.;
		informat FIPS_State_Code $2.;
		informat FIPS_County_Code $3.;
		informat Central_Outlying_County $8.;
		informat fipsjoin $5.;
		format CBSA_Code $234.;
		format Metropolitan_Division_Code best12.;
		format CSA_Code best12.;
		format CBSA_Title $100.;
		format MSA $29.;
		format MSA_Title $51.;
		format CSA_Title $62.;
		format County_Equivalent $28.;
		format State $20.;
		format FIPS_State_Code $2.;
		format FIPS_County_Code $3.;
		format Central_Outlying_County $8.;
		input CBSA_Code $
			Metropolitan_Division_Code CSA_Code CBSA_Title $
			MSA $
			MSA_Title $
			CSA_Title $
			County_Equivalent $
			State $
			FIPS_State_Code $
			FIPS_County_Code $
			Central_Outlying_County $;
		FIPSjoin=cats(fips_state_code, fips_county_code);

		if missing(fipsjoin) then
			delete;
	run;

%mend LoadCensus;


/********************************************************************************************************************************/
/***** LOADICU Macro - Raw import of a file directly from the site															*****/
/********************************************************************************************************************************/

%macro LoadICU;
	proc format;
		picture fipsfive low-high="99999";
	run;

	filename kff_ICU url 
		'https://s3-us-west-1.amazonaws.com/starschema.covid/KFF_US_ICU_BEDS.csv';

	data fips.ICU_BEDS;
		infile kff_icu delimiter=',' MISSOVER DSD firstobs=2;
		format COUNTRY_REGION $13.;
		format FIPS $5.;
		format COUNTY $25.;
		format STATE $20.;
		format ISO3166_1 $2.;
		format ISO3166_2 $2.;
		format HOSPITALS best12.;
		format ICU_BEDS best12.;
		format NOTE $100.;
		informat COUNTRY_REGION $100.;
		informat COUNTY $100.;
		informat STATE $100.;
		informat ISO3166_1 $2.;
		informat ISO3166_2 $2.;
		informat HOSPITALS best32.;
		informat ICU_BEDS best32.;
		informat NOTE $100.;
		informat fipstemp best32.;
		input COUNTRY_REGION  $
	            FIPStemp $
	            COUNTY  $
	            STATE  $
	            ISO3166_1  $
	            ISO3166_2  $
	            HOSPITALS ICU_BEDS NOTE  $;
		fipsjoin=scan(put(fipstemp, fipsfive.), 1, '.');
		drop fipstemp;
	run;

%mend loadICU;


/********************************************************************************************************************************/
/***** UPDATEJHUGIT Macro - THis is a macro that pulls new data from JHU. 													*****/
/********************************************************************************************************************************/

%macro UpdateJHUGit;
	%put NOTE: ***********************;
	%put NOTE: UPDATING GIT REPOSITORY;

	%put NOTE: Checking Repository Status;
	data _null_;
		rc0=GITFN_STATUS("/covid19data");
		put "NOTE: Initial GIT STATUS Return Code " rc0=;
		call symput("gitreturn", rc0);
	run;

	%put NOTE: gitreturn=&gitreturn;
	%if &gitreturn>0 %then
		%do;

			data _null_;
				%put NOTE: PULLING...;
				rc1=GITFN_PULL("/covid19data");
				put "NOTE: GIT PULL Return Code " rc1=;
				rc2=GITFN_STATUS("/covid19data");
				put "NOTE: GIT STATUS Return Code " rc2=;
			run;

		%end;
	%else %do;
		%put NOTE: No changes detected. No Pull Required;
	%end;
	%put NOTE: END UPDATING GIT REPO;
	%put NOTE: ***********************;
%mend UpdateJHUGit;

/********************************************************************************************************************************/
/***** BUILDDATASETS - another brevity macro. Should be put together														*****/
/********************************************************************************************************************************/

%macro buildDatasets(region, join);
	proc sql;
		create table &region._stacked as select "Confirmed" as measure
				, confirmed as value
				, filedate
				, &join
			from confirmed_&region._ts UNION select "Deaths" as measure
				, deaths as value
				, filedate
				, &join
			from deaths_&region._ts;
			
		create table &region._Joined as 
			select conf.*
				,death.deaths
				from 
					confirmed_&region._ts conf 
				left join deaths_&region._ts death 
				on 
					conf.&join=death.&join
					and 
					conf.filedate=death.filedate;
	quit;

%mend buildDatasets;


/********************************************************************************************************************************/
/***** JHUXW imports the JHU crosswalk file for fips etc.																	*****/
/********************************************************************************************************************************/

%macro JhuXW;
	FILENAME REFFILE 
		'/covid19data/csse_covid_19_data/UID_ISO_FIPS_LookUp_Table.csv';

	PROC IMPORT DATAFILE=REFFILE DBMS=CSV OUT=WORK.JHU_Crosswalk;
		GETNAMES=YES;
		DATAROW=2;
		GUESSINGROWS=200000;
	RUN;

%mend jhuxw;


/********************************************************************************************************************************/
/***** PLOTUSSTATES Macro - This is a runner for the PLOTSTATE macro for US States and for trajectories						*****/
/********************************************************************************************************************************/

%macro setgopts(h,w,ph,pw,gfmt=png);
	options orientation=landscape papersize=(&h.in &w.in) ;
	ods graphics on / reset width=&pw.in height=&ph.in  imagemap outputfmt=&gfmt ;
	ods html close;ods rtf close;ods pdf close;ods document close; 
%mend setgopts;


/********************************************************************************************************************************/
/***** CREATE_TRAJECTORIES Macro - This macro is just to make the process cleaner, and rerunable when needed. 				*****/
/********************************************************************************************************************************/

%MACRO CREATE_TRAJECTORIES;
	/*
	proc print data=us_augmented;
	var fips province_state country_region combined_key confirmed deaths dif_confirmed dif_deaths;
	where  Province_State='Georgia'
	and filedate='08apr2020'd;
	run;
	*/
	/********************************************************************/
	/***** 					STATE ROLLUP BLOCK						*****/
	/********************************************************************/
	proc sql; select max(filedate) into :filedate from us_augmented; quit;
	
	proc sql;
		create table state_totals as	
			select 
				 Province_State 
				,count(*) as freq
				,sum(confirmed) as total_confirmed
				,sum(deaths) as total_deaths
			from us_augmented
			where filedate=&filedate
			group by 
				Province_State 	
			order by 	
				Province_State 	
			;
	quit;
	
	/********************************************************************/
	/***** 					FIPS TRAJECTORIES BLOCK					*****/
	/********************************************************************/
	/*
	proc sql; 
		select fips, country_region, province_state, cbsa_title, csa_title, msa_title, county_equivalent, state
		,count(*) as freq, sum(confirmed) as conf,sum(deaths) as deaths
		from us_augmented
		group by fips, country_region, province_state, cbsa_title, csa_title, msa_title, county_equivalent, state
		order by fips, country_region, province_state, cbsa_title, csa_title, msa_title, county_equivalent, state
		;
	run;
	
	*/
	
			proc sql;
				create table _fips_trajectories as	
					select
						 fips
						,country_region 
						,Province_State
						,cbsa_title
						,combined_key
						,filedate 
						,count(*) 			as freq 			label = "Rollup Count"
						,sum(confirmed) 	as confirmed 		label="Confirmed"
						,sum(deaths) 		as deaths			label="Deaths"
						,sum(census2010pop) as census2010pop	label="2010 Populaton"
						,sum(hospitals)		as hospitals		label="Hospitals"
						,sum(icu_beds)		as icu_beds			label="ICU Beds"
					from us_augmented
					group by
						 fips					
						,country_region 
						,Province_State
						,cbsa_title	
						,combined_key
						,filedate
					order by
						 fips					
						,country_region 
						,Province_State
						,cbsa_title
						,combined_key
						,filedate
					;
			quit;
	
			proc expand data=_fips_trajectories out=_t1;
				by fips country_region province_state cbsa_title combined_key;
				id filedate;
				convert confirmed	= dif1_confirmed / transout=(dif 1);
				convert confirmed	= dif7_confirmed / transout=(dif 7);
				convert confirmed	= MA7_confirmed  / transout=(movave 7);
				convert deaths		= dif1_deaths 	 / transout=(dif 1);
				convert deaths		= dif7_deaths	 / transout=(dif 7);	
				convert deaths		= MA7_deaths 	 / transout=(movave 7);
			run;
			proc expand data=_t1 out=fips_trajectories;
				by fips country_region province_state cbsa_title combined_key;
				id filedate;
				convert dif1_confirmed	= MA7_new_confirmed  / transout=(movave 7);
				convert dif1_deaths		= ma7_new_deaths 	 / transout=(movave 7);
			run;
			/* add in a countdown from most recent to oldest for plotting */
			proc sort data=fips_trajectories; by fips country_region province_state cbsa_title combined_key descending filedate; run;
			data fips_trajectories;
				set fips_trajectories;
				by fips country_region province_state cbsa_title combined_key descending filedate;
				if first.fips then do;
					plotseq=0;
				end;
				plotseq+1;
				fd_weekday = put(filedate,DOWNAME3.);
				if census2010pop>0 then CasePerCapita = confirmed/census2010pop; else casepercapita=.;
				
				if icu_beds>0 then Caseperbed = confirmed/icu_beds; else caseperbed=.;
				if hospitals>0 then caseperhospital	= confirmed/hospitals; else caseperhospital=.;
				format casepercapita caseperbed caseperhospital 12.6;
			run;
			proc sort data=fips_trajectories ; by  fips country_region province_state cbsa_title combined_key filedate; run;
	
			proc datasets library=work; delete _t1 _fips_trajectories ; quit;
	/********************************************************************/
	/***** 					CBSA TRAJECTORIES BLOCK					*****/
	/********************************************************************/
			proc sql;
				create table _cbsa_trajectories as
					select
						 cbsa_title 
						,filedate 
						,count(*) 			as freq 		format=comma10.	label="Rollup Count"
						,sum(confirmed) 	as confirmed 	format=comma10.	label="Confirmed"
						,sum(deaths) 		as deaths		format=comma10.	label="Deaths"
						,sum(census2010pop) as census2010pop format=comma10.	label="2010 Populaton"
						,sum(hospitals)		as hospitals	format=comma10.	label="Hospitals"
						,sum(icu_beds)		as icu_beds		format=comma10.	label="ICU Beds"
					from fips_trajectories
					where ~missing(cbsa_title)
					group by
						 cbsa_title  	
						,filedate
					order by
						 cbsa_title 
						,filedate
					;
			quit;
			proc expand data=_cbsa_trajectories out=_t1;
				by cbsa_title;
				id filedate;
				convert confirmed	= dif1_confirmed / transout=(dif 1);
				convert confirmed	= dif7_confirmed / transout=(dif 7);
				convert confirmed	= MA7_confirmed  / transout=(movave 7);
				convert deaths		= dif1_deaths 	 / transout=(dif 1);
				convert deaths		= dif7_deaths	 / transout=(dif 7);	
				convert deaths		= MA7_deaths  	 / transout=(movave 7);
			run;
			proc expand data=_t1 out=cbsa_trajectories;
				by cbsa_title;
				id filedate;
				convert dif1_confirmed	= MA7_new_confirmed  / transout=(movave 7);
				convert dif1_deaths		= ma7_new_deaths 	 / transout=(movave 7);
			run;
			data cbsa_trajectories;
				set cbsa_trajectories;
				ma7_new_confirmed=sum(int(ma7_new_confirmed),0);
				ma7_new_deaths=sum(int(ma7_new_deaths),0);
			run;
			/* add in a countdown from most recent to oldest for plotting */
			proc sort data=cbsa_trajectories; by cbsa_title descending filedate; run;
			data cbsa_trajectories;
				set cbsa_trajectories;
				by cbsa_title descending filedate;
				if first.cbsa_title then do;
					plotseq=0;
				end;
				plotseq+1;
				fd_weekday = put(filedate,DOWNAME3.);
				if census2010pop>0 then CasePerCapita = confirmed/census2010pop; else casepercapita=.;
				if icu_beds>0 then Caseperbed = confirmed/icu_beds; else caseperbed=.;
				if hospitals>0 then caseperhospital	= confirmed/hospitals; else caseperhospital=.;
				format casepercapita caseperbed caseperhospital 12.6;
	
			run;
			proc sort data=cbsa_trajectories ; by cbsa_title filedate; run;
	
			
			proc datasets library=work; delete _t1 _cbsa_trajectories ; quit;
	
	/********************************************************************/
	/***** 			STATE TRAJECTORIES BLOCK						*****/
	/********************************************************************/
			proc sql;
				create table _state_trajectories as
					select
						 Province_State 
						,filedate 
						,count(*) 		as freq 		format=comma10.	label="Rollup Count"
						,sum(confirmed) as confirmed 	format=comma10.	label="Confirmed"
						,sum(deaths) as deaths			format=comma10.	label="Deaths"
						,sum(census2010pop) as census2010pop format=comma10.	label="2010 Populaton"
						,sum(hospitals)		as hospitals	format=comma10.	label="Hospitals"
						,sum(icu_beds)		as icu_beds		format=comma10.	label="ICU Beds"
					from fips_trajectories
			
					group by
						 Province_State 	
						,filedate
					order by
						 Province_State
						,filedate
					;
			quit;
			proc expand data=_state_trajectories out=_t1;
				by province_state;
				id filedate;
				convert confirmed	= dif1_confirmed / transout=(dif 1);
				convert confirmed	= dif7_confirmed / transout=(dif 7);
				convert confirmed	= MA7_confirmed  / transout=(movave 7);
				convert deaths		= dif1_deaths 	 / transout=(dif 1);
				convert deaths		= dif7_deaths	 / transout=(dif 7);
				convert deaths		= MA7_deaths  	 / transout=(movave 7);
			run;
			/*adding a comment */
			proc expand data=_t1 out=state_trajectories;
				by province_state;
				id filedate;
				convert dif1_confirmed	= MA7_new_confirmed  / transout=(movave 7);
				convert dif1_deaths		= ma7_new_deaths 	 / transout=(movave 7);
			run;
			
			data state_trajectories;
				set state_trajectories;
				ma7_new_confirmed=sum(int(ma7_new_confirmed),0);
				ma7_new_deaths=sum(int(ma7_new_deaths),0);
			run;
			/* add in a countdown from most recent to oldest for plotting */
			proc sort data=state_trajectories; by province_state descending filedate; run;
			data state_trajectories;
				set state_trajectories;
				by province_state descending filedate;
				if first.province_state then do;
					plotseq=0;
				end;
				plotseq+1;
				fd_weekday = put(filedate,DOWNAME3.);
				if census2010pop>0 then CasePerCapita = confirmed/census2010pop; else casepercapita=.;
				if icu_beds>0 then Caseperbed = confirmed/icu_beds; else caseperbed=.;
				if hospitals>0 then caseperhospital	= confirmed/hospitals; else caseperhospital=.;
				format casepercapita caseperbed caseperhospital 12.6;
			run;
			proc sort data=state_trajectories; by province_state filedate; run;
	
			
			proc datasets library=work; delete _t1 _state_trajectories _fips_trajectories ; quit;
	
	
	/********************************************************************/
	/***** 			Global TRAJECTORIES BLOCK						*****/
	/********************************************************************/
	
			proc sql;
				create table _global_trajectories as	
					select 
						 location
						,filedate
						,count(*) as freq				format=comma12.	label = "Rollup Count"
						,sum(confirmed) as confirmed 	format=comma12.	label="Confirmed"
						,sum(deaths) as deaths			format=comma12.	label="Deaths"
					from (
						select 
						 country_region
						,province_state
						,case when country_region = "China" then "China"
						      else cats(Country_region," ",Province_State) 
						      end as Location
						,filedate 
						,confirmed
						,deaths
						from global_joined
					)

					group by 
						 location
						 ,filedate
					order by 	
						 location
						,filedate
					;
			quit;
			
			/* add in a countdown from most recent to oldest for plotting */
			proc sort data=_global_trajectories; 
				by  location descending filedate; 
				run;
			data _global_trajectories;
				set _global_trajectories;
				by location descending filedate;
				if first.location then plotseq=0;
				plotseq+1;
				fd_weekday = put(filedate,DOWNAME3.);
			run;
			proc sort data=_global_trajectories; by location filedate; run;
			proc expand data=_global_trajectories out=_t1;
				id filedate;
				by location;
				convert confirmed	= dif1_confirmed / transout=(dif 1);
				convert confirmed	= dif7_confirmed / transout=(dif 7);
				convert deaths		= dif1_deaths 	 / transout=(dif 1);
				convert deaths		= dif7_deaths	 / transout=(dif 7);
				convert confirmed	= MA7_confirmed  / transout=(movave 7);
				convert deaths		= MA7_deaths  	 / transout=(movave 7);
			run;
			proc expand data=_t1 out=global_trajectories;
				id filedate;
				by location;
				convert dif1_confirmed	= MA7_new_confirmed  / transout=(movave 7);
				convert dif1_deaths		= ma7_new_deaths 	 / transout=(movave 7);
			run;
			data global_trajectories;
				set global_trajectories;
				ma7_new_confirmed=sum(int(ma7_new_confirmed),0);
				ma7_new_deaths=sum(int(ma7_new_deaths),0);
			run;
			proc sort data=global_trajectories; by location filedate; run;
	%let bulkformat=format confirmed deaths dif1_confirmed--dif7_deaths comma12. filedate mmddyy5.;
	%let bulklabel=label dif1_confirmed = "New Confirmed"
				    	 dif1_deaths = "New Deaths"
				    	 dif7_confirmed ="Confirmed: Seven Day Difference"
				    	 dif7_deaths ="Deaths: Seven Day Difference"
				    	 ma7_confirmed ="Cumulative Confirmed: Seven Day Moving Average"
				    	 ma7_deaths ="Cumulative Deaths: Seven Day Moving Average"
				    	 ma7_new_confirmed ="Seven Day Average of New Confirmed"
				    	 ma7_new_deaths ="Seven Day Average of New Deaths"
				    	 plotseq="Days"
				    	 fd_weekday="Weekday of File Date";
				  
	proc datasets library=work; 
		delete _global_trajectories _t1; 
		modify fips_trajectories; 	&bulkformat; &bulklabel;
		modify cbsa_trajectories;	&bulkformat; &bulklabel;
		modify state_trajectories;	&bulkformat; &bulklabel;
		modify global_trajectories;	&bulkformat; &bulklabel;
	quit;
%MEND CREATE_TRAJECTORIES;

/********************************************************************************************************************************/
/***** CHECKDELETEFILE - brevity file deleter																				*****/
/********************************************************************************************************************************/
/* https://documentation.sas.com/?docsetId=mcrolref&docsetTarget=n108rtvqj4uf7tn13tact6ggb6uf.htm&docsetVersion=9.4&locale=en */
%macro checkDeleteFile(file);
	%if %sysfunc(fileexist(&file)) ge 1 %then %do;
	   %let rc=%sysfunc(filename(temp,&file));
	   %let rc=%sysfunc(fdelete(&temp));
	   %put NOTE: Delete RC=&rc &file;
	%end; 
	%else %put NOTE: The file &file does not exist;
%mend checkDeleteFile; 

/********************************************************************************************************************************/
/***** RMPATHFILES Macro -This is a brevity function for removing plots and htmf files from the filesystem					*****/
/********************************************************************************************************************************/

%macro rmPathFiles(fpath,extension); 
	%let ct=0;
	%if %sysfunc(fileexist(&fpath)) ge 1 %then %do;
		filename _delpath "&fpath";
	    %put NOTE: Proceeding with listing files in &fpath;
		data _null_;
			legacy_count=0;
			current_count=0;
			handle=dopen("_delpath");
			if handle > 0 then do;
				count=dnum(handle);
				ct=0;
				do i=1 to count;
					memname=dread(handle,i);
					filepref = scan(memname,1,'.');
					fileext  = scan(memname,2,".");
					if fileext = "&extension" then do;
						ct+1;
						call symput(cats("file",ct),cats("&fpath./",memname));
						call symput("ct",ct);
					end;
				end;
			end;
			rc=dclose(handle);
		run;
		filename _delpath clear;
	%end;
	%else %do;
		%put NOTE: &fpath Does Not Exist RC=&rc;
	%end;
	%do j=1 %to &ct;
		%checkDeleteFile(&&file&j);
	%end;
	
%mend rmPathFiles;

/********************************************************************************************************************************/
/***** PLOTNATIONTRAJECTORY Macro - This is a runner for the national level for trajectories								*****/
/********************************************************************************************************************************/


%macro plotNationTrajectory(numback=30
				,maxplots=5
				,minconf=1000
				,mindeath=100
				,xvalues=(2000 to 42000 by 4000)
				,yvalues=(200 to 2600 by 400)
				,stplot=Y
				);
/* 	proc sort data= global_trajectories(where=(plotseq=1)) out = _s; */
/* 		by location; */
/* 	run; */
/* 	data _s2; set _s; */
		by location;
		mflag=0;
/* 		if first.location then do; */
/* 			total_confirmed=confirmed; */
/* 			total_deaths=deaths; */
/* 		end; */
/* 		else if ~missing(province_state) then do; */
/* 			total_confirmed+confirmed; */
/* 			total_deaths+deaths; */
/* 		end; */
/* 		output _s1; */
/* 		if last.location then do; */
/* 			if missing(province_state) then do; */
/* 				total_confirmed	= confirmed; */
/* 				total_deaths	= deaths; */
/* 			end; */
/* 			output _s2; */
/* 		end; */
/* 	run; */
/*  */
/* 	proc sort data= _s2;	by location; */
/* 		by descending ma7_new_confirmed; */
/* 	run; */
/* 	data _s2; set _s2; */
/* 		plotset=_n_; */
/* 		if plotset <= &maxplots; */
/* 	run; */
/* 	proc sql noprint; */
/* 		select distinct location into :creg1-:creg&maxplots  */
/* 		from _s2  */
/* 		order by location; */
/* 	run;	 */
/* 	%if &stplot=Y %then %do; */
/* 		%do nat=1 %to &maxplots; */
/* 				%put Working on &nat of &maxplots: From PLOTNations: "&&creg&nat" ; */
/* 			%plotstate(state="&&creg&nat",level=global,numback=&numback); */
/* 		%end; */
/* 	%end; */
	
	/********************************************************************/
	/***** 				Plot Global Trajectories	 				*****/
	/********************************************************************/

	ods graphics / reset=imagename imagename="AllNations" Height=10in width=16in;
	
	%let plottip= location filedate confirmed deaths;
	%let plottiplab="Location" "FileDate" "Confirmed" "Deaths";
	proc sql noprint;
		create table _globalplot as	
			select a.*,b.plotset from global_trajectories(where=(plotseq<=&numback and confirmed>&minconf and deaths>&mindeath)) a
			inner join _s2 b
			on a.location=b.location
			order by location, filedate;
	quit;
	
	proc sql noprint;
		create table _attribset as
			select b.location as value
			,id
			,color
			,fillcolor
			,markercolor
			,markersymbol
			,linecolor
			,textcolor
			,markertransparency
			from colormap a inner join _s2 b 
			on a.value=b.plotset;	
	quit;
	data _globalplot;
		set _globalplot;
		by location;
		if last.location then plot_label=location;
		else plot_label="";
	run;
	
		title h=1.5 "Global Top &maxplots National SARS-CoV-2 Trajectories";
		footnote   h=1 "Data Source: Johns Hopkins University - https://github.com/CSSEGISandData/SARS-CoV-2  Data Updated: &sysdate";
		footnote2  h=1 "Showing the Last &numback Days";
		footnote3  justify=right  height=0.5 "Samuel T. Croker - &sysdate9";
	ods proclabel "Top &maxplots Nation Trajectories"; 
	proc sgplot 
		data=_globalplot(where=(plotset<=30)) 
		noautolegend noborder 
		nocycleattrs 
		dattrmap=_attribset
		des="National Trajectories";
		series x=Confirmed y=Deaths  /
			group=location attrid=myid 
			markers 
			datalabel=plot_label
			datalabelattrs=(size=10) 
			tip=(&plottip) 
			tiplabel=(&plottiplab);
		xaxis grid minor minorgrid display=(noline)  type=log min=&minconf  LOGSTYLE=linear;
		yaxis grid minor minorgrid display=(noline)  type=log min=&mindeath LOGSTYLE=linear;
	run;

	proc datasets library=work nodetails nolist; delete _s2 _attribset _globalplot; quit;

%mend plotNations;

/********************************************************************************************************************************/
/***** PLOTCBSATRAJECTORY Macro - This is a runner for US CBSAs trajectories												*****/
/********************************************************************************************************************************/
		
%macro plotCBSATrajectory(numback=30
				,maxplots=5
				,minconf=5000
				,mindeath=500
				,xvalues=(2000 to 42000 by 4000)
				,yvalues=(200 to 2600 by 400)
				,stplot=Y
			);
/*  */
/* 	proc sort data=cbsa_trajectories(where=(plotseq=1)) out=_c; */
/* 		by descending ma7_new_confirmed; */
/* 	run; */
/* 	data _c; set _c; */
/* 		by descending  ma7_new_confirmed; */
/* 		plotset=_n_; */
/* 		if _n_ <= &maxplots then output; */
/* 	run; */
/*  */
/* 	proc sql noprint; */
/* 			select distinct cbsa_title into :cbsa1-:cbsa&maxplots  */
/* 			from _c  */
/* 			order by cbsa_title; */
/* 	quit; */
/* 	%if &stplot=Y %then %do; */
/* 		%do cb=1 %to &maxplots; */
/* 			%put Working on &cb of &maxplots: From PLOTCBSAs: "&&cbsa&cb"; */
/* 	 		%plotstate(state="&&cbsa&cb",level=cbsa,numback=&numback);  */
/* 		%end; */
/* 	%end; */
	/********************************************************************/
	/***** 				Plot CBSA Trajectories						*****/
	/********************************************************************/
	%let plottip=cbsa_title filedate confirmed deaths;
	%let plottiplab="CBSA" "FileDate" "Confirmed" "Deaths";
		
	proc sql noprint;
		create table _cbsaplot as	
			select a.*, b.plotset from cbsa_trajectories(where=(cbsa_title ~= "New York-Newark-Jersey City, NY-NJ-PA" and plotseq<=&numback and confirmed>&minconf and deaths>&mindeath)) a
			inner join _C b
			on a.CBSA_TITLE=b.CBSA_TITLE
			order by CBSA_TITLE, filedate;
	quit;
	
	proc sql noprint;
		create table _attribset as
			select b.CBSA_TITLE as value
			,id
			,color
			,fillcolor
			,markercolor
			,markersymbol
			,linecolor
			,textcolor
			,markertransparency
			from colormap a inner join _c b 
			on a.value=b.plotset;	
	quit;
	data _cbsaplot;
		set _cbsaplot;
		by CBSA_TITLE;
		if last.CBSA_TITLE then plot_label=CBSA_TITLE;
		else plot_label="";
	run;
	
	proc datasets  nodetails nolist lib=work;
		modify _cbsaplot;
			label casepercapita 	= "Case per Capita"
				  caseperbed 		= "Case per ICU Bed"
				  caseperhospital	= "Case per Hospital";
			format 
				  casepercapita   comma12.6
				  caseperbed 	  comma12.6	
				  caseperhospital comma12.6;
	quit;
	ods graphics  / reset=imagename imagename="AllCBSA";
		title h=1.5 "US CBSA Top &maxplots SARS-CoV-2 Trajectories";
		title2 h=0.95 "Removed: New York-Newark-Jersey City, NY-NJ-PA";
		footnote   h=1 "Data Source: Johns Hopkins University - https://github.com/CSSEGISandData/SARS-CoV-2  Data Updated: &sysdate";
		footnote2  h=1 "Showing the Last &numback Days";
		footnote3  h=0.5 justify=right "Samuel T. Croker - &sysdate9";
	ods proclabel "Top &maxplots US CBSA Trajectories"; 
	proc sgplot 
		data=_cbsaplot(where=(plotset<=&numback))
		noautolegend noborder 
		dattrmap=_attribset
		des="CBSA Trajectories";
		series x=Confirmed y=Deaths  / group=cbsa_title attrid=myid
			datalabel=plot_label  
			datalabelattrs=(size=10) 
			markers
			transparency=0.25
			tip=(&plottip) tiplabel=(&plottiplab) ;
		xaxis grid minor minorgrid display=(noline)  type=log values=&xvalues	LOGSTYLE=LOGEXPAND min=&minconf;
		yaxis grid minor minorgrid display=(noline)  type=log values=&yvalues	LOGSTYLE=LOGEXPAND min=&mindeath;
	run;

	proc datasets library=work nodetails nolist; delete _c _cbsaplot _attribset; quit;

%mend plotCBSAs;

/********************************************************************************************************************************/
/***** PLOTUSTRAJECTORY Macro - This is a runner for the US trajectories													*****/
/********************************************************************************************************************************/
%macro plotUSTrajectory(numback=30
				,maxplots=5
				,minconf=5000
				,mindeath=200
				,xvalues=(5000 to 40000 by 5000)
				,yvalues=(200 500 1000 1500 2000 2500 )
				,stplot=Y
				);

/* 	proc sort data=state_trajectories(where=(plotseq=1)) out=_us; */
/* 		by descending ma7_new_confirmed; */
/* 	run; */
/* 	data _us; set _us; */
/* 		by descending  ma7_new_confirmed; */
/* 		plotset=_n_; */
/* 		if _n_ <= &maxplots then output; */
/* 	run; */
/*  */
/* 	proc sql noprint; */
/* 			select distinct province_state into :usState1-:usState&maxplots  */
/* 			from _us  */
/* 			order by province_state; */
/* 	quit; */
/* 	%if &stplot=Y %then %do; */
/* 		%do st=1 %to &maxplots; */
/* 			%put Working on &st of &maxplots: From PLOTUSSTATES: "&&USSTATE&st"; */
/* 	 		%plotstate(state="&&USSTATE&st",level=state,numback=&numback);  */
/* 		%end; */
/* 	%end; */

	/********************************************************************/
	/***** Plot State Trajectories	 								*****/
	/********************************************************************/
	%let plottip=province_state filedate confirmed deaths;
	%let plottiplab="State" "FileDate" "Confirmed" "Deaths";
	
	proc sql noprint;
		create table _stateplot as	
			select a.*,b.plotset from state_trajectories(where=(province_state ~in  ("New York" "New Jersey") and plotseq<=&numback and confirmed>&minconf and deaths>&mindeath)) a
			inner join _us b
			on a.province_state=b.province_state
			order by province_state, filedate;
	quit;
	
	proc sql noprint;
		create table _attribset as
			select b.province_state as value
			,id
			,color
			,fillcolor
			,markercolor
			,markersymbol
			,linecolor
			,textcolor
			,markertransparency
			from colormap a inner join _us b 
			on a.value=b.plotset;	
	quit;
	data _stateplot;
		set _stateplot;
		by province_state;
		if last.province_state then plot_label=province_state;
		else plot_label="";
	run;
	
	proc datasets  nodetails nolist lib=work;
		modify _stateplot;
			label casepercapita 	= "Case per Capita"
				  caseperbed 		= "Case per ICU Bed"
				  caseperhospital	= "Case per Hospital";
			format 
				  casepercapita   comma12.6
				  caseperbed 	  comma12.6	
				  caseperhospital comma12.6;
	quit;
		ods graphics on / reset=imagename imagename="AllStates"  ;
	
		title h=1.5 "US State Top &maxplots SARS-CoV-2 Trajectories";
		title2 h=1.5 "Removed: New York, New Jersey";
		footnote   h=1.5 "Data Source: Johns Hopkins University - https://github.com/CSSEGISandData/SARS-CoV-2  Data Updated: &sysdate";
		footnote2  h=1.5 "Showing the Last &numback Days";
		footnote3  h=0.9 justify=right "Samuel T. Croker - &sysdate9";
	ods proclabel "Top &maxplots US States Trajectories"; 
	proc sgplot 
		data=_stateplot(where=(plotset<=&numback))
		noautolegend noborder 
		dattrmap=_attribset
		des="State Trajectories";
		series x=Confirmed y=Deaths  / group=province_state attrid=myid
			datalabel=plot_label
			datalabelattrs=(size=10) 
			markers 
			transparency=0.25
			tip=(&plottip) 
			tiplabel=(&plottiplab) ;
		xaxis grid minor minorgrid display=(noline)  type=log min=&minconf  values=&xvalues labelattrs=(size=15) valueattrs=(size=12) LOGSTYLE=LOGEXPAND ;
		yaxis grid minor minorgrid display=(noline)  type=log min=&mindeath values=&yvalues labelattrs=(size=15) valueattrs=(size=12) LOGSTYLE=LOGEXPAND ;
	run;

	proc datasets library=work nodetails nolist; delete _us _stateplot _attribset; quit;

%mend plotUSStates;


/********************************************************************************************************************************/
/***** PLOTSTATE Macro - plots any four panel region																		*****/
/********************************************************************************************************************************/
%macro plotstate(state=all,level=state,numback=30,gfmt=png);

	%if &level=state %then %do;
		%let datastatement=&level._trajectories(where=(province_state;
	%end;
	%else %if &level=global %then %DO;
		%let datastatement=&level._trajectories(where=(location;
	%end;
	%else %if &level=cbsa %then %DO;
		%let datastatement=&level._trajectories(where=(cbsa_title;
	%end;
		%let stlab=%SYSFUNC(compress(&STATE,' ",.<>;:`~!@#$%^&&*()-_=+'));
		%put Region=&state STLAB=&stlab;
		proc sql noprint;
			select trim(left(put(max(filedate),worddate32.))) into :maxdate from &datastatement.=&state and plotseq<=&numback));
		quit;
		%let gsym		=circlefilled; 
		%let gsize		=5;
		data _null_;call symput("stateunquote",compress(&state,'"'));run;

		title;footnote;
		%let confirmline=%str( yaxis=y lineattrs=(thickness=2 color=darkblue) );
		%let confirmmarker=%str( yaxis=y markerattrs=(size=8 color=darkblue symbol=circlefilled) FILLEDOUTLINEDMARKERS=TRUE MARKERFILLATTRS=(color=darkblue) MARKEROUTLINEATTRS=(color=darkblue) );
		%let deathline	=%str( yaxis=y2 lineattrs=(thickness=2 color=darkred) );
		%let deathmarker=%str( yaxis=y2 markerattrs=(size=8 color=darkred symbol=circlefilled) FILLEDOUTLINEDMARKERS=TRUE MARKERFILLATTRS=(color=darkred) MARKEROUTLINEATTRS=(color=darkred) );
		%let overlayopts=%str( border=FALSE walldisplay=NONE height=4.5in width=7.5in xaxisopts=(label=" " timeopts=(tickvalueformat=mmddyy5.)) yaxisopts=(label="Confirmed") y2axisopts=(label="Deaths"));
		%let xaxisopts  =%str( xaxisopts=(griddisplay=Off display=(label ticks tickvalues) gridattrs=(color=BWH )  type=time timeopts=(interval=day tickvaluerotation=diagonal tickvaluefitpolicy=rotatealways splittickvalue=FALSE) ));
		%let yaxisopts  =%str( yaxisopts=(griddisplay=Off display=(label ticks tickvalues) gridattrs=(color=BWH)));
		ODS PROCLABEL "&stateunquote Profile";
		proc template;
			define statgraph lattice;
			begingraph / designwidth=1632px designheight=960px ;
				entrytitle textattrs=(size=15)  &state;
				entrytitle  "SARS-CoV-2 Situation Report as of &maxdate";
				entryfootnote "Data Source: Johns Hopkins University - https://github.com/CSSEGISandData/COVID-19 Data Updated: &sysdate";
				entryfootnote  "Showing the Last &numback Days" ;
				entryfootnote  textattrs=(size=7) halign=right "Samuel T. Croker - &sysdate9" ;

				layout lattice / border=FALSE pad=3 opaque=true rows=2 columns=2 columngutter=3;
					cell; 
						cellheader; entry "Cumulative Infections and Deaths" / textattrs=(size=12); endcellheader;
				      	layout overlay / &overlayopts &yaxisopts xaxisopts=(display=(label ticks tickvalues)) y2axisopts=(display=(label ticks tickvalues));
				      		barchart  category=filedate response=confirmed 	/ stat=sum datatransparency=0.75;
							linechart category=filedate response=deaths 	/ stat=sum &deathline ;
				      	endlayout;
				    endcell;
				    
					cell; 
						cellheader; entry "  Cumulative Infections and Deaths" / textattrs=(size=10); endcellheader;
				      	layout overlay /&overlayopts &xaxisopts &yaxisopts y2axisopts=(display=(label ticks tickvalues));
				      		scatterplot	y=confirmed x=filedate / &confirmmarker	;
							seriesplot	y=confirmed x=filedate / &confirmline	;
							scatterplot	y=deaths 	x=filedate / &deathmarker 	;
							seriesplot	y=deaths 	x=filedate / &deathline		;
				      	endlayout;						 
				    endcell;
				    
					cell; 
						cellheader; entry "New Infections and Deaths" / textattrs=(size=10); endcellheader;
				      	layout overlay /&overlayopts &yaxisopts xaxisopts=(display=(label ticks tickvalues)) y2axisopts=(display=(label ticks tickvalues));
				      		barchart    category=filedate 	response=dif1_confirmed / stat=sum datatransparency=0.75;
							scatterplot x		=filedate 	y		=dif1_deaths 	/ &deathmarker;
						endlayout; 
					endcell;
				    
					cell; 
						cellheader; entry "New Infections and Deaths - Seven Day Moving Average" / textattrs=(size=10); endcellheader;
				      	layout overlay /&overlayopts  &yaxisopts xaxisopts=(display=(label ticks tickvalues)) y2axisopts=(display=(label ticks tickvalues));
				      		barchart  category=filedate response=ma7_new_confirmed 	/ stat=sum datatransparency=0.75;
							linechart category=filedate response=ma7_new_deaths 	/ stat=sum &deathline;
				      	endlayout;	
			      	endcell;
				endlayout;
			endgraph;
			end;
		run;
		ods graphics /reset=imagename imagename="&stlab" ;
		proc sgrender 
			 data=&datastatement.=&state and plotseq<=&numback)) template=lattice des="&stlab";
		run;

%mend plotstate;

/********************************************************************************************************************************/
/***** INSERTPDFREPORTHEADER Macro - Inserts title frame and preps for the rest of the pdf report							*****/
/********************************************************************************************************************************/

%macro InsertPDFReportHeader(style=styles.raven);
	ods escapechar="^";  
	title;
	footnote;
	data _null_;
		filedate=input("&sysdate9",date9.);
		call symput("cvdate",trim(left(put(max(filedate),worddate32.))));
	run;
	/* Create a data set containing the desired title text */
		/* Create a data set containing the desired title text */
		data test;
			length text $100;
		   text="SARS-CoV-2 2019 Pandemic (COVID-19) Report - &cvdate"; output;
		run;
	
	/******** PDF ********/
	ods graphics / outputfmt=png;
	ods pdf file="&outputpath./AllStatesAndCountries.pdf" startpage=no style=&style; 
	
	/* Insert a logo and blank lines (used to move the title text to the center of page) */
	footnote1 j=c "Beware of drawing conclusions from this data. Lagged confirmations and deaths are contained.";
	footnote2 j=r "Samuel T. Croker";
	footnote3 j=c "Data Source: Johns Hopkins University - https://github.com/CSSEGISandData/SARS-CoV-2  Data Updated: &cvdate";
	ods pdf text='^S={preimage="coronavirus-image.png"}';
	ods pdf text="^20n";
	
	/* Output the title text */
	ODS PROCLABEL="SARS-CoV-2 Report";
	proc report data=test noheader 
	     style(report)={rules=none frame=void} 
	     style(column)={font_weight=bold font_size=25pt just=c};
	run;
	
	/* Output the remainder of the report */
	ods pdf startpage=yes;
%mend InsertPDFReportHeader;




/********************************************************************************************************************************/
/***** PLOTPATHS Macro - 							*****/
/********************************************************************************************************************************/


%macro plotPaths(level,procvar,title,maxplots=10,plotvariable=ma7_new_deaths,style=styles.htmlblue);
	proc sort data=&level._trajectories; by &procvar filedate; run;

	data _trajectories;
		set &level._trajectories;;
		label days_since_death1 = "Days Since First Death";
		by &procvar filedate;
		array ddflag[2]  _temporary_;
		retain ddflag;
		if first.&procvar then do;
			days_since_death1 = 0;
			ddflag[1]=0;
		end; 
		if ddflag[1] = 0 then do;
			if dif1_deaths > 0.5 then ddflag[1] = 1;
		end;
		else do;
			 days_since_death1 + 1;
		end;
	
		/* PER CAPITA, BEDS, HOSPITALS CALC */
		%local i next_var vars;
		%let vars= census2010pop icu_beds hospitals;	
		%do i=1 %to %sysfunc(countw(&vars));
			%let next_var = %scan(&vars, &i);
			if  &next_var > 0 then do;
				&plotvariable._per_&next_var = &plotvariable / &next_var;
			end;
			else &plotvariable._per_&next_var=.;
			format &plotvariable._per_&next_var percent8.5;
		%end;
		/* END PER CAPITA */
		
		if ddflag[1] then output;
	run;
	proc sort data=_trajectories; by &procvar descending filedate; run;
	data _trajectories ; set _trajectories;
		by &procvar descending filedate;
		array dd[1] _temporary_;
		if first.&PROCVAR then dd[1]=0;
		if ma7_new_deaths > 0.5 and dd[1]=0 then do;
			lastdeath = 1;
			dd[1] = 1;
		end;
		else lastdeath=0;
	run;
	
		proc sort data=_trajectories(where=(plotseq=1)) out=_t ;
			by descending &plotvariable;
		run;
		data _t; set _t;
			by descending  &plotvariable;
			plotset=_n_;
		run;
		proc sort data=_t ;by descending deaths;run;
		data _t; set _t;
			by descending  deaths;
			plotdeathset=_n_;
		run;
		proc sort data=_t ;by descending &plotvariable._per_census2010pop;run;
		data _t; set _t;
			by descending  &plotvariable._per_census2010pop;
			plotpercapita=_n_;
		run;
		proc sql noprint;
			create table Death_trajectories as	
				select a.*
				,b.plotset
				,b.plotdeathset
				,b.plotpercapita
				,case when a.plotseq=1 or a.lastdeath=1 then a.&procvar else "" end as plot_label
				from _trajectories a
				inner join _t b
				on a.&procvar=b.&procvar
				order by &procvar, filedate;
		quit;
	
	%if &maxplots=0 %then %do;
		proc sql noprint;
			select ceil((max(days_since_death1)+.01)/10)*10 into :deathmax from death_trajectories;
		quit; 
		%put deathmax=&deathmax ;
		
		title;footnote;
			title 	  h=1 "All &title SARS-CoV-2 Trajectories";
			footnote  h=1"Data Source: Johns Hopkins University - https://github.com/CSSEGISandData/SARS-CoV-2  Data Updated: &sysdate";
			footnote3 h=0.9 justify=right "Samuel T. Croker - &sysdate9";
			ods proclabel "Top &maxplots &title Death Paths"; 
			proc sgplot 
				data=death_trajectories(where=(&plotvariable>0 ))
				noautolegend nocycleattrs noborder
				des="&title Paths Since Death One";
				series x=days_since_death1 y=&plotvariable  / group=&procvar 
					datalabel=plot_label datalabelpos=top
					datalabelattrs=(size=10  ) 
					lineattrs =(thickness=2 pattern=solid )
					transparency=0.25;
				xaxis minor /*grid minorgrid*/display=(noline)   max=%eval(&deathmax) offsetmax=0 offsetmin=0  labelattrs=(size=10) valueattrs=(size=12) values=(0 to &deathmax by 10 ) ;
				yaxis minor /*grid minorgrid*/display=(noline)  type=log labelattrs=(size=15) valueattrs=(size=12) LOGSTYLE=LOGEXPAND ;
			run;
	%end;
	%else %if &maxplots < 0 %then %do;
		%let maxplots=%eval(-1*&maxplots);
		proc sql noprint;
			select ceil((max(days_since_death1)+.01)/20)*20 into :deathmax from death_trajectories(where=(ma7_new_deaths>0 and plotdeathset<=abs(&maxplots)));
		quit; 
		%put deathmax=&deathmax ;
			title 	  h=1 "Top &maxplots &title Deaths SARS-CoV-2 Trajectories";
			footnote  h=1 "Data Source: Johns Hopkins University - https://github.com/CSSEGISandData/SARS-CoV-2  Data Updated: &sysdate";
			footnote3 h=0.9 justify=right "Samuel T. Croker - &sysdate9";
			ods proclabel "Top &maxplots &title Death Paths"; 
			proc sgplot 
				data=death_trajectories(where=(&plotvariable>0 and plotdeathset<=abs(&maxplots)))
				noautolegend nocycleattrs noborder
				des="&title Deaths Paths Since Death One";
				series x=days_since_death1 y=&plotvariable  / group=&procvar 
					datalabel=plot_label datalabelpos=top
					datalabelattrs=(size=10 ) 
					lineattrs =(thickness=2 pattern=solid ) 
					transparency=0.25;
				xaxis minor  /*grid minorgrid*/display=(noline)   max=%eval(&deathmax) offsetmax=0 offsetmin=0        labelattrs=(size=10) valueattrs=(size=12) values=(0 to &deathmax by 20 ) ;
				yaxis minor /*grid minorgrid*/display=(noline)  type=log labelattrs=(size=15) valueattrs=(size=12) LOGSTYLE=LOGEXPAND ;
			run;			
			%if "&level" = "cbsa" %then %do;
				proc sgplot 
					data=death_trajectories(where=(&plotvariable>0 and plotpercapita<=abs(&maxplots)))
					noautolegend nocycleattrs noborder
					des="&title Deaths Per Capita Paths Since Death One";
					series x=days_since_death1 y=&plotvariable._per_census2010pop  / group=&procvar 
						datalabel=plot_label datalabelpos=top
						datalabelattrs=(size=10 ) 
						lineattrs =(thickness=2 pattern=solid ) 
						transparency=0.25;
					xaxis minor  /*grid minorgrid*/display=(noline)   max=%eval(&deathmax) offsetmax=0 offsetmin=0        labelattrs=(size=10) valueattrs=(size=12) values=(0 to &deathmax by 20 ) ;
					yaxis minor /*grid minorgrid*/display=(noline)  type=log labelattrs=(size=15) valueattrs=(size=12) LOGSTYLE=LOGEXPAND ;
				run;
			%end;
	%end;
	%else %do;
		proc sql noprint;
			select ceil((max(days_since_death1)+.01)/10)*10 into :deathmax from death_trajectories(where=(plotset<=abs(&maxplots)));
		quit; 
		%put deathmax=&deathmax ;
			title 	  h=1 "&title - Top &maxplots SARS-CoV-2 Trajectories";
			footnote  h=1 "Data Source: Johns Hopkins University - https://github.com/CSSEGISandData/SARS-CoV-2  Data Updated: &sysdate";
			footnote3 h=0.9 justify=right "Samuel T. Croker - &sysdate9";
			ods proclabel "Top &maxplots &title Death Paths"; 
			proc sgplot noborder
				data=death_trajectories(where=(&plotvariable>0 and plotset<=abs(&maxplots)))
				noautolegend nocycleattrs
				des="&title Paths Since Death One";
				series x=days_since_death1 y=&plotvariable  / group=&procvar 
					datalabel=plot_label datalabelpos=top
					datalabelattrs=(size=10 ) 
					lineattrs =(thickness=2 pattern=solid )
					transparency=0.25;
				xaxis minor /*grid minorgrid*/display=(noline)  max=%eval(&deathmax) offsetmax=0 offsetmin=0        labelattrs=(size=15) valueattrs=(size=12) values=(0 to &deathmax by 10 ) ;
				yaxis minor /*grid minorgrid*/display=(noline) type=log labelattrs=(size=15) valueattrs=(size=12) LOGSTYLE=LOGEXPAND ;
			run;
			%if "&level" = "cbsa" %then %do;
				proc sgplot noborder
					data=death_trajectories(where=(&plotvariable>0 and plotpercapita<=abs(&maxplots) ))
					noautolegend nocycleattrs
					des="&title Paths Since Death One";
					series x=days_since_death1 y=&plotvariable._per_census2010pop  / group=&procvar 
						datalabel=plot_label datalabelpos=top
						datalabelattrs=(size=10 ) 
						lineattrs =(thickness=2 pattern=solid )
						transparency=0.25;
					xaxis minor /*grid minorgrid*/display=(noline)  max=%eval(&deathmax) offsetmax=0 offsetmin=0        labelattrs=(size=15) valueattrs=(size=12) values=(0 to &deathmax by 10 ) ;
					yaxis minor /*grid minorgrid*/display=(noline) type=log labelattrs=(size=15) valueattrs=(size=12) LOGSTYLE=LOGEXPAND ;
				run;
			%end;
	%end;
%mend PlotPaths;



%macro plot_emerging(level,procvar,maxplots=20);
	
	data _plottemp;
		set _global;
		by &procvar filedate;
		if ~first.&procvar then do;
			lag_dif7_confirmed=lag(dif7_confirmed);
			dif = lag_dif7_confirmed-dif7_confirmed;
		end;
		if last.&procvar then output;
	run;
	proc sql noprint;
			select &procvar into :loc1-:loc&maxplots
			from _plottemp 
			order by dif ;
	quit;
	%do i=1 %to 2;*&maxplots;
		%put Working on &i of &maxplots: From PLOTlocS: "&&loc&i";
 		%plotstate(state="&&loc&i",level=state,numback=30); 
	%end;
	
%mend;


