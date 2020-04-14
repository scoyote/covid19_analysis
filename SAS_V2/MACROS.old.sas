%macro loadTS_Global(type=confirmed); 
	data _null_;call symput("ptype",propcase("&type"));run;
	
	FILENAME REFFILE "/covid19data/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_&type._global.csv";
	
	PROC IMPORT DATAFILE=REFFILE DBMS=CSV OUT=WORK.T_IMPORT_TS;
		GETNAMES=YES;
	RUN;
	
	proc datasets library=work;
		modify T_IMPORT_TS;
			rename  'Country/Region'n= country_region;
			rename 	'Province/State'n= province_state;
			rename  lat				 = latitude;
			rename  long 			 = longitude;
	quit;
	proc sql noprint;
		create table work.Coordinate_resolution as
			select distinct 
				country_region
				,province_state
				,latitude
				,longitude
			from T_IMPORT_TS
			order by country_region, province_state;
	quit;
	data WORK.T_IMPORT_TS;
		set WORK.T_IMPORT_TS;
		if missing(province_state) then
			province_state='National';
		location=cats(province_state, "-", country_region);
		drop province_state country_region latitude longitude;
	run;
	
	/* Roll this up by location so we can use the _numeric_ 
		shortcut for the dates - this is a very small dataset */
	proc sort data=work.t_import_ts; 
		by location; 
	run;
	proc transpose data=WORK.T_IMPORT_TS 
			out=work.&TYPE._TS 
			prefix=UpDate_t;
		var _numeric_;
		by location;
	run;
	proc datasets library=work;
		modify &TYPE._TS;
			rename update_t1= &type;
			label &type	= "&ptype";
			label location	= "Location";
			rename _name_ 	= temp_FileDate;
	quit;
	
	/* Convert the string date to a real date */
	data &TYPE._TS;	
		set &TYPE._TS;
		FileDate = input(temp_filedate,mmddyy8.);
		format filedate yymmdd10.;
		format &type comma12.;
		drop temp_filedate;
	run;
	proc sort data=WORK.&TYPE._TS 
			   out=WORK.&type._global_TS; 
		by location filedate; 
	run;

	proc datasets library=work; 
		delete t_import_ts &type._ts; 
	quit;
	
%mend loadTS_global;

%macro loadTS_US(type=confirmed);  
	data _null_;call symput("ptype",propcase("&type"));run;
	
	FILENAME REFFILE "/covid19data/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_&type._US.csv";
	
	PROC IMPORT DATAFILE=REFFILE DBMS=CSV OUT=WORK.T_IMPORT_TS;
		GETNAMES=YES;
	RUN;
	
	proc sort data=t_import_ts; by fips; run;
	
	data t_import_ts; 
		set t_import_ts;
		by fips;
		/*fix the case of missing fips for the transpose
		to have a single column */
		if missing(fips) then do;
			if first.fips then a=1; else a+1;
			fipsjoin=cats("f",a);
		end;
		else FIPSJOIN=put(fips,fipsfive.);
		drop %if &type=deaths %then %do; population %end; a Combined_Key  Country_Region  Province_State FIPS admin2 code3 iso2 iso3 lat long_ UID;
	run;
	
	
	proc datasets library=work;
		modify T_IMPORT_TS;
			rename fipsjoin=fips;
			label fips='FIPS';
	quit;
	
	proc sql; 
		select fips, count(*) as freq
			from t_import_ts 
			group by fips;
	quit;

	
	proc sort data=work.t_import_ts; 
		by fips; 
	run;
	proc transpose data=WORK.T_IMPORT_TS 
			out=work.&TYPE._TS 
			prefix=UpDate_t
			;
		var _numeric_;
		by fips;
	run;
	proc datasets library=work;
		modify &TYPE._TS;
			rename update_t1= &type;
			rename _name_ 	= temp_FileDate;
	quit;
	
	/* Convert the string date to a real date */
	data &TYPE._TS;	
		set &TYPE._TS;
		FileDate = input(temp_filedate,mmddyy8.);
		format filedate yymmdd10.;
		format &type comma12.;
		label filedate="TS Date";
		label &type="&ptype";
		drop temp_filedate;
	run;
	proc sort data=WORK.&TYPE._TS 
			   out=WORK.&type._US_TS; 
		by fips filedate; 
	run;

	proc datasets library=work; 
		delete t_import_ts &type._ts; 
	quit;
	
%mend loadTS_US;


%macro LoadCensus;
	/* County to CBSA Crosswalk: Source: https://www.census.gov/programs-surveys/metro-micro/about/delineation-files.html */
	/* https://www2.census.gov/programs-surveys/metro-micro/geographies/reference-files/2018/delineation-files/list1_Sep_2018.xls */
	data fips.CBSA_County_Crosswalk   ;
		
		infile "/covid_analysis/data/MSA_CountyFipsCrosswalk.csv" 
			delimiter = ',' 
			MISSOVER 
			DSD  
			firstobs=2 ;
		informat CBSA_Code $234. ;
		informat Metropolitan_Division_Code best32. ;
		informat CSA_Code best32. ;
		informat CBSA_Title $48. ;
		informat MSA $29. ;
		informat MSA_Title $51. ;
		informat CSA_Title $62. ;
		informat County_Equivalent $28. ;
		informat State_Name $20. ;
		informat FIPS_State_Code $2. ;
		informat FIPS_County_Code $3. ;
		informat Central_Outlying_County $8. ;
		format CBSA_Code $234. ;
		format Metropolitan_Division_Code best12. ;
		format CSA_Code best12. ;
		format CBSA_Title $48. ;
		format MSA $29. ;
		format MSA_Title $51. ;
		format CSA_Title $62. ;
		format County_Equivalent $28. ;
		format State $20. ;
		format FIPS_State_Code $2. ;
		format FIPS_County_Code $3. ;
		format Central_Outlying_County $8. ;
		input
			CBSA_Code $
			Metropolitan_Division_Code 
			CSA_Code 
			CBSA_Title $
			MSA $
			MSA_Title $
			CSA_Title $
			County_Equivalent $
			State $
			FIPS_State_Code $
			FIPS_County_Code $
			Central_Outlying_County $
		;
		FIPSjoin=cats(fips_state_code,fips_county_code);
		if missing(fipsjoin) then delete;
	run;

%mend LoadCensus;

%macro LoadICU;
proc format;
	picture fipsfive low-high= "99999";
run;

filename kff_ICU url 'https://s3-us-west-1.amazonaws.com/starschema.covid/KFF_US_ICU_BEDS.csv';
data fips.ICU_BEDS    ;
	infile kff_icu delimiter = ',' MISSOVER DSD  firstobs=2 ;
	   format COUNTRY_REGION $13. ;
	   format FIPS $5. ;
	   format COUNTY $25. ;
	   format STATE $20. ;
	   format ISO3166_1 $2. ;
	   format ISO3166_2 $2. ;
	   format HOSPITALS best12. ;
	   format ICU_BEDS best12. ;
	   format NOTE $100. ;
	   informat COUNTRY_REGION $100. ;
	   informat COUNTY $100. ;
	   informat STATE $100. ;
	   informat ISO3166_1 $2. ;
	   informat ISO3166_2 $2. ;
	   informat HOSPITALS best32. ;
	   informat ICU_BEDS best32. ;
	   informat NOTE $100. ;
	   informat fipstemp best32.;
	input
	            COUNTRY_REGION  $
	            FIPStemp $
	            COUNTY  $
	            STATE  $
	            ISO3166_1  $
	            ISO3166_2  $
	            HOSPITALS
	            ICU_BEDS
	            NOTE  $
	;
	fipsjoin = scan(put(fipstemp,fipsfive.),1,'.');
	
	drop fipstemp;
run;
%mend loadICU;

%macro UpdateJHUGit;
	%put NOTE: ***********************;
	%put NOTE: UPDATING GIT REPOSITORY;
	data _null_;
		rc0 = GITFN_STATUS("/covid19data");
		put "NOTE: Initial GIT STATUS Return Code " rc0=;
		call symput("gitreturn",rc0);
	run;
	%put NOTE: gitreturn=&gitreturn;
	%if &gitreturn>0 %then %do;
		data _null_;
			%put NOTE: PULLING...;
		    rc1= GITFN_PULL("/covid19data");
		    put "NOTE: GIT PULL Return Code " rc1=;
		    rc2 = GITFN_STATUS("/covid19data");
		    put "NOTE: GIT STATUS Return Code " rc2=;
		run;
	%end;
	%put NOTE: END UPDATING GIT REPO;
	%put NOTE: ***********************;
%mend UpdateJHUGit;


%macro buildDatasets(region,join);
	proc sql;
		create table &region._stacked as	
			select 
				"Confirmed" as measure
				,confirmed as value
				,filedate
				,&join
			from confirmed_&region._ts
		UNION
			select 
				"Deaths" as measure
				,deaths as value
				,filedate
				,&join
			from deaths_&region._ts
		;
		create table &region._Joined as	
			select conf.*, death.deaths
			from 
				confirmed_&region._ts conf
			left join
				deaths_&region._ts death
			on conf.&join=death.&join
			and conf.filedate=death.filedate
		;
	quit;
%mend buildDatasets;


