/************************************************************************************/
/***** Data Section - retrieve the raw data from GitHub, then make it usable 	*****/
/***** 				  This program avoids CBSAs, but there is a loss of the  	*****/
/*****				  ability to look at conjoined geographic areas that span 	*****/
/*****				  state boundaries, which are common.You can put associated *****/
/*****				  FIPS together though - just has to be manual. Create a 	*****/
/*****				  new column that identifies the new grouping, then manually ****/
/*****				  assign FIPS codes by giving the new column the same value *****/
/*****				  for the FIPS rows that are associated.  			    	*****/
/************************************************************************************/	
/* Step 1: Set up the permanent library and URL fileref to the data */
	libname pCovid '/repositories/covid19_analysis/SAS_V2/data';

	filename usConf 	url 'https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_confirmed_US.csv';
	filename glConf 	url	'https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_confirmed_global.csv';
	filename usDeath	url 'https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_deaths_US.csv';
	filename glDeath	url	'https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_deaths_global.csv';

%macro BuildDS(fname,region,type);
	 %let keeps=;
	 %if &fname=usconf %then %do;
        %let sortkey=Province_state fips combined_key;
        %let colset=('UID','COMBINED_KEY','COUNTRY_REGION',"province_state",'FIPS','ADMIN2','CODE3','ISO2','ISO3','LAT','LONG_');    
        %let scolset=UID COMBINED_KEY COUNTRY_REGION province_state FIPS ADMIN2 CODE3 ISO2 ISO3 LAT LONG_;   
 	%end;
    %if &fname=usdeath %then %do;
        %let sortkey=Province_state fips combined_key;
        %let colset=('UID','POPULATION','COMBINED_KEY','COUNTRY_REGION',"province_state",'FIPS','ADMIN2','CODE3','ISO2','ISO3','LAT','LONG_');    
        %let scolset=UID POPULATION COMBINED_KEY COUNTRY_REGION province_state FIPS ADMIN2 CODE3 ISO2 ISO3 LAT LONG_;    
        %let keeps=POPULATION;
    %end;
    %else %if &region=GL %then %do;
        %let sortkey='COUNTRY/REGION'n 'Province/State'n;
        %let colset=('COUNTRY/REGION','Province/State','LAT','LONG');    
        %let scolset='COUNTRY/REGION'n 'Province/State'n LAT LONG;    
    %end;
	PROC IMPORT DATAFILE=&fname DBMS=CSV OUT=WORK._IMPORT_TS replace  ; 
		GETNAMES=YES; 
		GUESSINGROWS=1500;
	run;

	proc contents 
		data=_import_ts 
		out=_cont 
		noprint; 
	run;
	
	proc sql noprint;
		select count(*) into :columnCount 
		from _cont 
		where 
			type=1 
			and upcase(name) not in &colset;
			
		select compress(name) into :txcols separated by '"n "' 
		from _cont 
		where 
			type=1 
			and upcase(name) not in &colset;
	quit;
	proc sort data=_import_ts; 
		by &scolset;
	run;
	proc transpose 
		 data	= _IMPORT_ts 
		 out	= _import_t 
		 prefix	= UpDate_t;
		var "&txcols"n;
		by &scolset;
	run;
	
	proc datasets library=work nolist nodetails ;
		modify _import_t;
		rename update_t1	= &type;
		rename _name_		= FileDate;
	quit;
	data _analysis_temp;
		set _import_t;
		format 
			reportdate 		mmddyy5. 
			&type			comma12.
			;
		reportdate=input(filedate,mmddyy10.);
		keep 
			&sortkey
			reportdate 
			&type
			&keeps;
	run;
	proc sort data=_analysis_temp; 
		by  &sortkey 
			reportdate ;
	run;
	proc expand data=_analysis_temp out=_tx;
	   by &sortkey;
	   id reportdate;
   			convert &type	= Daily&type / transout=(dif 1);
	run;
	
	data pcovid.&region._&type;
		set _tx;
		daily&type=floor(sum(daily&type));
	run;

/* 	proc datasets library=work nodetails nolist;  */
/* 		delete  */
/* 			_tx */
/* 			_cont  */
/* 			_analysis_temp */
/* 			_import_t  */
/* 			_import_ts; */
/* 	QUIT; */
	%if &region=GL %then %do;
		proc datasets library=pcovid nodetails nolist; 		
			modify &region._&type.; 
			rename 'COUNTRY/REGION'n = Country_Region;
			rename 'Province/State'n = Province_state;
		quit;
	%end;
%mend;

%BuildDS(usconf,US,confirmed);
%BuildDS(usdeath,US,deaths);
%BuildDS(glConf,GL,confirmed);
%BuildDS(gldeath,GL,deaths);


proc sql;
    create table _US_Daily as
        select a.*, b.population, b.dailydeaths, b.deaths
        from
            pcovid.US_CONFIRMED a 
        inner join
            pcovid.US_DEATHS b
        on a.fips=b.fips
        and a.combined_key=b.combined_key
        and a.province_state=b.province_state
        and a.reportdate=b.reportdate
        order by 
             a.fips
            ,a.province_state
            ,a.combined_key
            ,a.reportdate
        ;
quit;

proc expand data=_us_daily out=pcovid.US_DAILY;
    by fips province_state combined_key;
    id reportdate;
    convert DailyConfirmed = MA7_Cases  / transout=(movave 7);
    convert DailyDeaths    = MA7_Deaths / transout=(movave 7);
run;

proc sql;
    create table _GL_Daily as
        select a.*, b.dailydeaths, b.deaths
        from
            pcovid.GL_CONFIRMED a 
        inner join
            pcovid.GL_DEATHS b
        on a.country_region=b.country_region
        and a.province_state=b.province_state
        and a.reportdate=b.reportdate
        order by 
             a.country_region
            ,a.province_state
            ,a.reportdate
        ;
quit;

proc expand data=_GL_daily out=pcovid.GL_DAILY;
    by country_region province_state;
    id reportdate;
    convert DailyConfirmed = MA7_Cases  / transout=(movave 7);
    convert DailyDeaths    = MA7_Deaths / transout=(movave 7);
run;

proc datasets library=work nodetails nolist ;
    delete _us_daily _gl_daily;
quit;








