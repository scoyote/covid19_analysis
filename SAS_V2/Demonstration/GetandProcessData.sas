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
/* Commonly Changed Settings */
%let analysisStartDate	='13may2020'd;
%let plotStartDate		='01apr2020'd;
%let regionName			=Georgia;


/* Other settings */
%let regionColumn		=province_state;
/************************************************************************************/

/* Step 0: clear work library */
	proc datasets library=WORK kill nodetails nolist; run; quit;
	/* be really careful with this if you keep lots in work */
	
/* Step 1: Set up the permanent library and URL fileref to the data */
	libname pCovid '/repositories/covid19_analysis/SAS_V2/data';
	
	
	/* This is the containing folder as of 5/27/2020: https://github.com/CSSEGISandData/COVID-19/blob/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_confirmed_US.csv */
	filename us_jhu url 'https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_confirmed_US.csv';

/* step 1; Import the csv directly from the website. I normally dont like proc import but it works here. */
	PROC IMPORT DATAFILE=us_jhu DBMS=CSV OUT=WORK._IMPORT_TS replace ; 
		GETNAMES=YES;
	run;

/* These data is arranged with every new date in a column. We need to turn this into a long dataset. */
/*  step 1: Extract metadata
/* 		   Create a dataset of column names that is used to specify transpose columns in proc transpose later */
	proc contents 
		data=_import_ts 
		out=_cont 
		noprint; 
	run;
	
	%let colset=('UID','POPULATION','COMBINED_KEY','COUNTRY_REGION',"province_state",'FIPS','ADMIN2','CODE3','ISO2','ISO3','LAT','LONG_');	
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
	%put NOTE: Sanity Check: There were &columnCount Date Columns -> txcols="&txcols";
	
	
/* Step 2: transpose the dataset using the columns in step 1. THis makes more sense in a  */
/* 		daily ETL operation for which it was designed. Here it just saves typing. Without it, */
/* 		you have to type out all the date column names... */
	proc sort data=_import_ts; 
		by uid fips Combined_Key Country_Region province_state admin2 code3 iso2 iso3 lat long_ ;
	run;
	/* Rotate the dataset to make it long rather than wide */
	proc transpose 
		 data	= _IMPORT_ts 
		 out	= _import_t 
		 prefix	= UpDate_t;
		var "&txcols"n;
		by uid fips Combined_Key Country_Region province_state admin2 code3 iso2 iso3 lat long_ ;
	run;
	
/* Step 4: update column names the fast way*/
	proc datasets library=work nolist nodetails ;
		modify _import_t;
		rename update_t1	= CumulativeCases;
		rename _name_		= FileDate;
	quit;
	
/* Step 5: Create the analysis dataset - select only some columns etc... format */

	data _analysis_temp;
		set _import_t;
		format 
			reportdate 		mmddyy5. 
			CumulativeCases	comma12.
			;
		reportdate=input(filedate,mmddyy10.);
		keep 
			&regionColumn 
			fips 
			combined_key 
			reportdate 
			cumulativeCases;
		if &regionColumn="&regionName.";
	run;
	proc sort data=_analysis_temp; 
		by  &regionColumn 
			fips 
			combined_key 
			reportdate ;
	run;
	proc expand data=_analysis_temp out=&regionName._fips;
	   by fips;
	   id reportdate;
   			convert cumulativeCases	= DailyCases / transout=(dif 1);
	run;
	
/* Step 7: Create region master time series by summing up cases over date - the filter was done already */
	proc sql;
		create table &regionName._overall as	
			select reportdate
				,floor(sum(DailyCases)) as DailyCases
			from &regionName._fips
			group by 
				reportdate
			order by 
				reportdate
			;
	quit;
	
/* step 6: delete datasets */
	proc datasets library=work; 
		delete 
			_cont 
			_analysis_temp
			_import_t 
			_import_ts;
	quit;