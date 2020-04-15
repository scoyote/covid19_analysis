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
		informat MSA $29.;
		informat MSA_Title $51.;
		informat CSA_Title $62.;
		informat County_Equivalent $28.;
		informat State_Name $20.;
		informat FIPS_State_Code $2.;
		informat FIPS_County_Code $3.;
		informat Central_Outlying_County $8.;
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

%macro UpdateJHUGit;
	%put NOTE: ***********************;
	%put NOTE: UPDATING GIT REPOSITORY;

	data _null_;
		rc0=GITFN_STATUS("/covid19data");
		put "NOTE: Initial GIT STATUS Return Code " rc0=;
		call symput("gitreturn", rc0);
	run;

	%put NOTE: gitreturn=&gitreturn;

	%if &gitreturn>0 %then
		%do;

			data _null_;
				%put NOTE:
PULLING...;
				rc1=GITFN_PULL("/covid19data");
				put "NOTE: GIT PULL Return Code " rc1=;
				rc2=GITFN_STATUS("/covid19data");
				put "NOTE: GIT STATUS Return Code " rc2=;
			run;

		%end;
	%put NOTE: END UPDATING GIT REPO;
	%put NOTE: ***********************;
%mend UpdateJHUGit;

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

%macro JhuXW;
	FILENAME REFFILE 
		'/covid19data/csse_covid_19_data/UID_ISO_FIPS_LookUp_Table.csv';

	PROC IMPORT DATAFILE=REFFILE DBMS=CSV OUT=WORK.JHU_Crosswalk;
		GETNAMES=YES;
		DATAROW=2;
		GUESSINGROWS=200000;
	RUN;

%mend jhuxw;

%macro setgopts(h,w,ph,pw);
	options orientation=landscape papersize=(&h.in &w.in) ;
	ods graphics on / reset width=&pw.in height=&ph.in  imagemap outputfmt=svg;
	ods html close;ods rtf close;ods pdf close;ods document close; 
%mend setgopts;


%macro plotstate(state=all,level=state,plotback=30);
	%if &state=all %then %do;
		%if &level=state %then %do;
			proc sql noprint; 
				select count(distinct province_state) into :stcount from &level._trajectories;
				select distinct province_state into :state1 - :state%cmpres(&stcount) from &level._trajectories; 
			quit;
		%end;
		%else %do;
			proc sql noprint; 
				select count(distinct country_region) into :stcount from &level._trajectories;
				select distinct country_region into :state1 - :state%cmpres(&stcount) from &level._trajectories; 
			quit;
		%end;
	%end;
	%else %do;
		%let stcount=1;
		%let state1=&state;
	%end;
	
	footnote   h=1 "Data Source: Johns Hopkins University - https://github.com/CSSEGISandData/COVID-19  Data Updated: &sysdate";
	footnote2  h=1 "Showing the Last &daysback Days";
	footnote3  justify=right  height=0.5 "Samuel T. Croker - &sysdate9";
	ods proclabel " "; 
	
	%do st = 1 %to &stcount;
		title "&&state&st COVID-19 Situation Report";
		title2 "Prevalence and Deaths";
		title2 "New Cases and New Deaths";
		ods proclabel "&&state&st";
		proc sgplot data=&level._trajectories(where=(province_state="&&state&st" and plotseq<=&plotback)) nocycleattrs des="&&state&st New Cases and Deaths" ;
			vbar  filedate / response=dif1_confirmed stat=sum datalabel=fd_weekday datalabelfitpolicy= rotate datalabelattrs=(size=2);
			vline filedate / response=dif1_deaths stat=sum y2axis lineattrs=(thickness=1 );
			yaxis ; 
			y2axis ;
			xaxis  valueattrs=(size=7) fitpolicy=rotatethin;
			keylegend / location=outside;
			format filedate mmddyy5.;
		run;	
		title3 "Seven Day Moving Average";
		proc sgplot data=&level._trajectories(where=(province_state="&&state&st" and plotseq<=&plotback)) nocycleattrs des="&&state&st New Cases and Deaths" ;
			vbar  filedate / response=dif7_confirmed stat=sum datalabel=fd_weekday datalabelfitpolicy= rotate datalabelattrs=(size=2);
			vline filedate / response=dif7_deaths stat=sum y2axis lineattrs=(thickness=1 );
			yaxis ; 
			y2axis ;
			xaxis  valueattrs=(size=7) fitpolicy=rotatethin;
			keylegend / location=outside;
			
			format filedate mmddyy5.;
		run;	
		title2 "Prevalence and Deaths";
		title3;
		ods proclabel " ";
		proc sgplot data=&level._trajectories(where=(province_state="&&state&st" and plotseq<=&plotback)) nocycleattrs des="&&state&st Prevalence Bar";
			vbar  filedate / response=confirmed stat=sum ;
			vline filedate / response=deaths stat=sum y2axis lineattrs=(thickness=1 );
			yaxis ; 
			y2axis ;
			xaxis  valueattrs=(size=7) fitpolicy=rotatethin;
			keylegend / location=outside;
			
			format filedate mmddyy5.;
		run;
		ods proclabel " ";
		proc sgplot data=&level._trajectories(where=(province_state="&&state&st" and plotseq<=&plotback)) description="&&state&st Prevalence Line";
			scatter y=confirmed x=filedate  / 
				FILLEDOUTLINEDMARKERS 
				MARKERFILLATTRS=(color='CX6599C9') 
				MARKEROUTLINEATTRS=(color='CX6599C9') 
				markerattrs=(symbol=CircleFilled color='CX6599C9');
			series y=confirmed x=filedate  	/ 
				lineattrs=(color='blue') 
				legendlabel=" ";
			scatter  y=deaths x=filedate 	/  
				FILLEDOUTLINEDMARKERS 
				MARKERFILLATTRS=(color='CXEDAF64') 
				MARKEROUTLINEATTRS=(color='CXEDAF64')  
				markerattrs=(symbol=CircleFilled color='cxedaf64' ) 
				y2axis ;
			series y=deaths x=filedate 		/ 
				y2axis lineattrs=(color='red') 
				legendlabel=" ";
			yaxis ; 
			y2axis ;
			xaxis type=discrete fitpolicy=rotatethin valueattrs=(size=5)	valuesformat=mmddyy5. valuesrotate=diagonal ;
			keylegend / location=outside;
			
			format filedate mmddyy5.;
		run;

	%end;
%mend plotstate;



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
	
			proc expand data=_fips_trajectories out=fips_trajectories;
				by fips country_region province_state cbsa_title combined_key;
				convert confirmed	= dif1_confirmed / transout=(dif 1);
				convert confirmed	= dif7_confirmed / transout=(dif 7);
				convert deaths		= dif1_deaths 	 / transout=(dif 1);
				convert deaths		= dif7_deaths	 / transout=(dif 7);	
			run;
			/* add in a countdown from most recent to oldest for plotting */
			proc sort data=fips_trajectories; by fips country_region province_state cbsa_title combined_key descending filedate; run;
			data fips_trajectories;
				set fips_trajectories;
				by fips descending filedate;
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
	
			proc datasets library=work; delete _fips_trajectories ; quit;
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
			proc expand data=_cbsa_trajectories out=cbsa_trajectories;
				by cbsa_title;
				convert confirmed	= dif1_confirmed / transout=(dif 1);
				convert confirmed	= dif7_confirmed / transout=(dif 7);
				convert deaths		= dif1_deaths 	 / transout=(dif 1);
				convert deaths		= dif7_deaths	 / transout=(dif 7);	
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
	
			
			proc datasets library=work; delete _cbsa_trajectories ; quit;
	
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
					from fips_trajectories
			
					group by
						 Province_State 	
						,filedate
					order by
						 Province_State
						,filedate
					;
			quit;
			proc expand data=_state_trajectories out=state_trajectories;
				by province_state;
				convert confirmed	= dif1_confirmed / transout=(dif 1);
				convert confirmed	= dif7_confirmed / transout=(dif 7);
				convert deaths		= dif1_deaths 	 / transout=(dif 1);
				convert deaths		= dif7_deaths	 / transout=(dif 7);	
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
			run;
			proc sort data=state_trajectories; by province_state filedate; run;
	
			
			proc datasets library=work; delete _state_trajectories _fips_trajectories ; quit;
	
	
	/********************************************************************/
	/***** 			Global TRAJECTORIES BLOCK						*****/
	/********************************************************************/
	
			proc sql;
				create table _global_trajectories as	
					select
						 country_region
						,province_state
						,cats(Country_region," ",Province_State) as Location 
						,filedate 
						,count(*) as freq				format=comma12.	label = "Rollup Count"
						,sum(confirmed) as confirmed 	format=comma12.	label="Confirmed"
						,sum(deaths) as deaths			format=comma12.	label="Deaths"
					from global_joined
					group by 
						  country_region
						,province_state
						,cats(Country_region," ",Province_State)
						,filedate
					order by 	
						 country_region
						,province_state
						,cats(Country_region," ",Province_State)
						,filedate
					;
			quit;
			
			/* add in a countdown from most recent to oldest for plotting */
			proc sort data=_global_trajectories; 
				by  country_region province_state location descending filedate; 
				run;
			data _global_trajectories;
				set _global_trajectories;
				by country_region province_state location descending filedate;
				if first.location then plotseq=0;
				plotseq+1;
				fd_weekday = put(filedate,DOWNAME3.);
			run;
			proc sort data=_global_trajectories; by country_region province_state filedate; run;
			proc expand data=_global_trajectories out=global_trajectories;
				by country_region province_state;
				convert confirmed	= dif1_confirmed / transout=(dif 1);
				convert confirmed	= dif7_confirmed / transout=(dif 7);
				convert deaths		= dif1_deaths 	 / transout=(dif 1);
				convert deaths		= dif7_deaths	 / transout=(dif 7);	
			run;
			
			
			
	%let bulkformat=format confirmed deaths dif1_confirmed--dif7_deaths comma12. filedate mmddyy5.;
	%let bulklabel=label dif1_confirmed = "New Confirmed"
				    	 dif1_deaths = "New Deaths"
				    	 dif7_confirmed ="New Confirmed: Seven Day Moving Average"
				    	 dif7_deaths =" New Deaths: Seven Day Moving Average"
				    	 plotseq="Days"
				    	 fd_weekday="Weekday of File Date";
				  
	proc datasets library=work; 
		delete _global_trajectories; 
		modify fips_trajectories; 	&bulkformat; &bulklabel;
		modify cbsa_trajectories;	&bulkformat; &bulklabel;
		modify state_trajectories;	&bulkformat; &bulklabel;
		modify global_trajectories;	&bulkformat; &bulklabel;
	quit;
%MEND CREATE_TRAJECTORIES;






















