
data colormap;                 
/* 	set covid.colors;   */
length Value 8. FillColor $30;
input value FillColor $;
informat fillcolor $30.; 
/* RENAME COLORNUM=VALUE;      */
retain ID 'myid'            
     Show 'AttrMap';  
COLOR		= fillcolor;
linecolor	= fillcolor;
MARKERCOLOR	= fillcolor;
textcolor	= fillcolor;
MARKERTRANSPARENCY=0.5;
markersymbol='plus';
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
				%put NOTE: PULLING...;
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

%macro setgopts(h,w,ph,pw,gfmt=svg);
	options orientation=landscape papersize=(&h.in &w.in) ;
	ods graphics on / reset width=&pw.in height=&ph.in  imagemap outputfmt=&gfmt ;
	ods html close;ods rtf close;ods pdf close;ods document close; 
%mend setgopts;





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
	
			
			proc datasets library=work; delete _t1 _state_trajectories _fips_trajectories ; quit;
	
	
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
			proc expand data=_global_trajectories out=_t1;
				id filedate;
				by country_region province_state;
				convert confirmed	= dif1_confirmed / transout=(dif 1);
				convert confirmed	= dif7_confirmed / transout=(dif 7);
				convert deaths		= dif1_deaths 	 / transout=(dif 1);
				convert deaths		= dif7_deaths	 / transout=(dif 7);
				convert confirmed	= MA7_confirmed  / transout=(movave 7);
				convert deaths		= MA7_deaths  	 / transout=(movave 7);
			run;
			proc expand data=_t1 out=global_trajectories;
				id filedate;
				by country_region province_state;
				convert dif1_confirmed	= MA7_new_confirmed  / transout=(movave 7);
				convert dif1_deaths		= ma7_new_deaths 	 / transout=(movave 7);
			run;
			
			
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

/* https://documentation.sas.com/?docsetId=mcrolref&docsetTarget=n108rtvqj4uf7tn13tact6ggb6uf.htm&docsetVersion=9.4&locale=en */
%macro checkDeleteFile(file);
	%if %sysfunc(fileexist(&file)) ge 1 %then %do;
	   %let rc=%sysfunc(filename(temp,&file));
	   %let rc=%sysfunc(fdelete(&temp));
	   %put NOTE: Delete RC=&rc &file;
	%end; 
	%else %put NOTE: The file &file does not exist;
%mend checkDeleteFile; 

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


%macro plotNations(numback=30
				,maxplots=5
				,minconf=1000
				,mindeath=100
				,xvalues=(2000 to 42000 by 4000)
				,yvalues=(200 to 2600 by 400)
				);
	proc sort data= global_trajectories(where=(plotseq=1)) out = _s;
		by country_region Province_state;
	run;
	data _s1 _s2; set _s;
		by country_region Province_state;
		mflag=0;
		if first.country_region then do;
			total_confirmed=confirmed;
			total_deaths=deaths;
		end;
		else if ~missing(province_state) then do;
			total_confirmed+confirmed;
			total_deaths+deaths;
		end;
		output _s1;
		if last.country_region then do;
			if missing(province_state) then do;
				total_confirmed	= confirmed;
				total_deaths	= deaths;
			end;
			output _s2;
		end;
	run;

	proc sort data= _s2;	by country_region Province_state;
		by descending ma7_new_confirmed;
	run;
	data _s2; set _s2;
		plotset=_n_;
		if plotset <= &maxplots;
	run;
	proc sql noprint;
		select distinct country_region into :creg1-:creg&maxplots 
		from _s2 
		order by country_region;
	run;
	%do nat=1 %to &maxplots;
			%put Working on &nat of &maxplots: From PLOTNations: "&&creg&nat" ;
		%plotstate(state="&&creg&nat",level=global,plotback=&numback);
	%end;
	
	
	/********************************************************************/
	/***** 				Plot Global Trajectories	 				*****/
	/********************************************************************/

	ods graphics / reset=imagename imagename="AllNations" Height=10in width=16in;
	
	%let plottip=country_region location filedate confirmed deaths;
	%let plottiplab="Country" "Location" "FileDate" "Confirmed" "Deaths";
	proc sql noprint;
		create table _globalplot as	
			select a.*,b.plotset from global_trajectories(where=(plotseq<=&numback and confirmed>&minconf and deaths>&mindeath)) a
			inner join _s2 b
			on a.location=b.location
			order by location, filedate;
	quit;
	
	proc sql noprint;
		create table _attribset as
			select b.location as value, a.*
			from colormap a inner join _s2 b 
			on a.value=b.plotset;	
	quit;
	data _globalplot;
		set _globalplot;
		by location;
		if last.location then plot_label=location;
		else plot_label="";
	run;
	
		title "Global National Trajectories";
		footnote   h=1 "Data Source: Johns Hopkins University - https://github.com/CSSEGISandData/SARS-CoV-2  Data Updated: &sysdate";
		footnote2  h=1 "Showing the Last &daysback Days";
		footnote3  justify=right  height=0.5 "Samuel T. Croker - &sysdate9";
		ods proclabel " "; 
	proc sgplot 
		data=_globalplot(where=(plotset<=30)) noautolegend nocycleattrs dattrmap=_attribset;
		series x=Confirmed y=Deaths  / markers group=location attrid=myid 
			tip=(&plottip) tiplabel=(&plottiplab)  datalabel=plot_label;
		xaxis grid minor minorgrid type=log min=&minconf  LOGSTYLE=linear;
		yaxis grid minor minorgrid type=log min=&mindeath LOGSTYLE=linear;
	run;

	proc datasets library=work nodetails nolist; delete _s2 _attribset _globalplot; quit;

%mend plotNations;

		
%macro plotCBSAs(numback=30
				,maxplots=5
				,minconf=2000
				,mindeath=200
				,xvalues=(2000 to 42000 by 4000)
				,yvalues=(200 to 2600 by 400)
			);

	proc sort data=cbsa_trajectories(where=(plotseq=1)) out=_c;
		by descending ma7_new_confirmed;
	run;
	data _c; set _c;
		by descending  ma7_new_confirmed;
		plotset=_n_;
		if _n_ <= &maxplots then output;
	run;

	proc sql noprint;
			select distinct cbsa_title into :cbsa1-:cbsa&maxplots 
			from _c 
			order by cbsa_title;
	quit;
	%do cb=1 %to &maxplots;
		%put Working on &cb of &maxplots: From PLOTCBSAs: "&&cbsa&cb";
 		%plotstate(state="&&cbsa&cb",level=cbsa,plotback=&numback); 
	%end;
	
	/********************************************************************/
	/***** 				Plot CBSA Trajectories						*****/
	/********************************************************************/
	%let daysback=&numback;
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
			select b.CBSA_TITLE as value, a.*
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

		title2 h=0.95 "Removed: New York-Newark-Jersey City, NY-NJ-PA";
		footnote   h=1 "Data Source: Johns Hopkins University - https://github.com/CSSEGISandData/SARS-CoV-2  Data Updated: &sysdate";
		footnote2  h=1 "Showing the Last &daysback Days";
		footnote3  h=0.5 justify=right "Samuel T. Croker - &sysdate9";
	
	proc sgplot 
		data=_cbsaplot(where=(plotset<=&numback))
		noautolegend dattrmap=_attribset;
		ods proclabel " "; 
	
		series x=Confirmed y=Deaths  / group=cbsa_title attrid=myid
			datalabel=cbsa_title  
			markers
			markerattrs=(size=7) 
			datalabelattrs=(size=5) 
			transparency=0.25
			tip=(&plottip) tiplabel=(&plottiplab) ;
		xaxis grid minor minorgrid type=log values=&xvalues	LOGSTYLE=logexpand ;
		yaxis grid minor minorgrid type=log values=&yvalues	LOGSTYLE=LOGEXPAND ;
	run;

	proc datasets library=work nodetails nolist; delete _c _cbsaplot _attribset; quit;

%mend plotCBSAs;


%macro plotUSStates(numback=30
				,maxplots=5
				,minconf=5000
				,mindeath=200
				,xvalues=(2000 to 42000 by 4000)
				,yvalues=(200 to 2400 by 400)
				);

	proc sort data=state_trajectories(where=(plotseq=1)) out=_us;
		by descending ma7_new_confirmed;
	run;
	data _us; set _us;
		by descending  ma7_new_confirmed;
		plotset=_n_;
		if _n_ <= &maxplots then output;
	run;

	proc sql noprint;
			select distinct province_state into :usState1-:usState&maxplots 
			from _us 
			order by province_state;
	quit;
	%do st=1 %to &maxplots;
		%put Working on &st of &maxplots: From PLOTUSSTATES: "&&USSTATE&st";
 		%plotstate(state="&&USSTATE&st",level=state,plotback=&numback); 
	%end;

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
			select b.province_state as value, a.*
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
	
		title h=2 "US State SARS-CoV-2 Trajectories";
		title2 h=1.5 "Removed: New York, New Jersey";
		footnote   h=1.5 "Data Source: Johns Hopkins University - https://github.com/CSSEGISandData/SARS-CoV-2  Data Updated: &sysdate";
		footnote2  h=1.5 "Showing the Last &daysback Days";
		footnote3  h=0.9 justify=right "Samuel T. Croker - &sysdate9";
		ods proclabel " "; 
	proc sgplot 
		data=_stateplot(where=(plotset<=&numback))
		noautolegend dattrmap=_attribset;
		series x=Confirmed y=Deaths  / group=province_state attrid=myid
			datalabel=province_state
			markers markerattrs=(size=12) 
			datalabelattrs=(size=12) 
			transparency=0.25
			tip=(&plottip) 
			tiplabel=(&plottiplab) ;
		xaxis grid minor minorgrid type=log min=&minconf  labelattrs=(size=15) valueattrs=(size=12) LOGSTYLE=LOGEXPAND values = (5000 to 40000 by 5000);
		yaxis grid minor minorgrid type=log min=&mindeath labelattrs=(size=15) valueattrs=(size=12) LOGSTYLE=LOGEXPAND values = (200 500 1000 1500 2000 2500 ) ;
	run;

	proc datasets library=work nodetails nolist; delete _us _stateplot _attribset; quit;

%mend plotUSStates;



%macro plotstate(state=all,level=state,plotback=30,gfmt=svg);

/* 	%if &state="all" %then %do; */
/* 		%if &level=state %then %do; */
/* 			%let ff=province_state; */
/* 			proc sql noprint;  */
/* 				select count(distinct province_state) into :stcount from &level._trajectories; */
/* 				select distinct province_state into :state1 - :state%cmpres(&stcount) from &level._trajectories;  */
/* 			quit; */
/* 		%end; */
/* 		%else %if level=global %then %do; */
/* 			%let ff=country_region; */
/* 			proc sql noprint;  */
/* 				select count(distinct country_region) into :stcount from &level._trajectories; */
/* 				select distinct country_region into :state1 - :state%cmpres(&stcount) from &level._trajectories;  */
/* 			quit; */
/* 		%end; */
/* 		%else %if level=cbsa %then %do; */
/* 			%let ff=cbsa_title; */
/* 			proc sql noprint;  */
/* 				select count(distinct cbsa_title) into :stcount from &level._trajectories; */
/* 				select distinct cbsa_title into :state1 - :state%cmpres(&stcount) from &level._trajectories;  */
/* 			quit; */
/* 		%end; */
/* 		 */
/* 	%end; */
/* 	%else %do; */
/* 		%let stcount=1; */
/* 		%let state1=&state; */
/* 	%end; */
	
/* 	%if &gfmt=svg %then %do; */
/* 		%let gsym=symbol=death; */
/* 		%let gsize=20; */
/* 	%end; */
/* 	%else %do; */
/* 		%let gsym=circlefilled; */
/* 		%let gsize = 5; */
/* 	%end; */

	%if &level=state %then %do;
		%let datastatement=&level._trajectories(where=(province_state;
	%end;
	%else %if &level=global %then %DO;
		%let datastatement=&level._trajectories(where=(country_region;
	%end;
	%else %if &level=cbsa %then %DO;
		%let datastatement=&level._trajectories(where=(cbsa_title;
	%end;


/* 	%do st = 1 %to &stcount; */
		%let stlab=%SYSFUNC(compress(&STATE,' ",.<>;:`~!@#$%^&&*()-_=+'));
		%put Region=&state STLAB=&stlab;
		proc sql noprint;
			select trim(left(put(max(filedate),worddate32.))) into :maxdate from &datastatement.=&state and plotseq<=&numback));
		quit;
/* 		data _null_; call symput("maxdate",put(&md,worddate32.)); run; */
		%let gsym		=circlefilled; 
		%let gsize		=5;
		
		%let confirmline=%str( yaxis=y lineattrs=(thickness=2 color=darkblue) );
		%let confirmmarker=%str( yaxis=y markerattrs=(size=10 color=darkblue) FILLEDOUTLINEDMARKERS=TRUE MARKERFILLATTRS=(color=darkblue) MARKEROUTLINEATTRS=(color=darkblue) );
		%let deathline	=%str( yaxis=y2 lineattrs=(thickness=2 color=darkred) );
		%let deathmarker=%str( yaxis=y2 markerattrs=(size=10 color=darkred) FILLEDOUTLINEDMARKERS=TRUE MARKERFILLATTRS=(color=darkred) MARKEROUTLINEATTRS=(color=darkred) );
		%let overlayopts=%str(height=4.5in width=7.5in xaxisopts=(label=" " timeopts=(tickvalueformat=mmddyy5.)) yaxisopts=(label="Confirmed") y2axisopts=(label="Deaths"));
		%let xaxisopts  =%str( xaxisopts=(griddisplay=Off gridattrs=(color=BWH ) type=time timeopts=(interval=day tickvaluerotation=diagonal tickvaluefitpolicy=rotatealways splittickvalue=FALSE) ));
		%let yaxisopts  =%str( yaxisopts=(griddisplay=ON gridattrs=(color=BWH)));
		proc template;
			define statgraph lattice;
			begingraph / designwidth=1632px designheight=960px ;
				entrytitle textattrs=(size=15)  &state;
				entrytitle  "SARS-CoV-2 Situation Report as of &maxdate";
				entryfootnote "Data Source: Johns Hopkins University - https://github.com/CSSEGISandData/COVID-19 Data Updated: &sysdate";
				entryfootnote  "Showing the Last &numback Days" ;
				entryfootnote  textattrs=(size=7) halign=right "Samuel T. Croker - &sysdate9" ;

				layout lattice / border=false pad=3 opaque=true rows=2 columns=2 columngutter=3;
					cell; 
						cellheader; entry "  Cumulative Infections and Deaths  ." / textattrs=(size=12); endcellheader;
				      	layout overlay / &overlayopts &yaxisopts;
				      		barchart  category=filedate response=confirmed 	/ stat=sum datatransparency=0.75;
							linechart category=filedate response=deaths 	/ stat=sum &deathline ;
				      	endlayout;
				    endcell;
				    
					cell; 
						cellheader; entry "  Cumulative Infections and Deaths  ." / textattrs=(size=12); endcellheader;
				      	layout overlay / &overlayopts &xaxisopts &yaxisopts;
				      		scatterplot	y=confirmed x=filedate / &confirmmarker	;
							seriesplot	y=confirmed x=filedate / &confirmline	;
							scatterplot	y=deaths 	x=filedate / &deathmarker	;
							seriesplot	y=deaths 	x=filedate / &deathline		;
				      	endlayout;						 
				    endcell;
				    
					cell; 
						cellheader; entry "  New Infections and Deaths - Seasonality Is Problematic  ." / textattrs=(size=12); endcellheader;
				      	layout overlay / &overlayopts &yaxisopts;
				      		barchart    category=filedate 	response=dif1_confirmed / stat=sum datatransparency=0.75;
							scatterplot x		=filedate 	y		=dif1_deaths 	/ &deathmarker;
						endlayout; 
					endcell;
				    
					cell; 
						cellheader; entry "  New Infections and Deaths - Seasonality Smoothed with Seven Day Moving Average    ." / textattrs=(size=12); endcellheader;
				      	layout overlay / &overlayopts  &yaxisopts;
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
			 data=&datastatement.=&state and plotseq<=&numback)) template=lattice des="State/Regional Panel for &stlab";
		run;

/* 	%end; */
%mend plotstate;

