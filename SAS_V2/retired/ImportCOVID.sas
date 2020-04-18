%macro LoadCSV(infilepath,outdataset,typer,counter);
	data JHU&outdataset    ;
		   infile "&infilepath" 
		   delimiter = ',' 
		   MISSOVER 
		   DSD
		   lrecl=32767 
		   firstobs=2 ;
		/* this format section sets the file structure across the 3/22 boundary */
		format FIPS $5. ;
		format Admin2 $50. ;
		format Province_State $50. ;
		format Country_Region $50. ;
		format Last_Update datetime. ;
		format Lat best12. ;
		format Long_ best12. ;
		format Confirmed comma. ;
		format Deaths comma. ;
		format Recovered comma. ;
		format Active comma. ;
		format Combined_Key $50. ;
		
		format AUG_filedate yymmdd10.;
		label AUG_filedate="File Date";
		
		format AUG_State $50.  ;
		format AUG_country $50. ;
		
		informat FIPStemp best32. ;
		informat Admin2 $50. ;
		informat Province_State $50. ;
		informat Country_Region $50. ;
		informat Last_Update anydtdtm40. ;
		informat Lat best32. ;
		informat Long_ best32. ;
		informat Confirmed best32. ;
		informat Deaths best32. ;
		informat Recovered best32. ;
		informat Active best32. ;
		informat Combined_Key $50. ;
		/* read in the new format */
		%if &typer=1 %then %do;
			input
			   FIPStemp $
			   Admin2  $
			   Province_State  $
			   Country_Region  $
			   Last_Update
			   Lat
			   Long_
			   Confirmed
			   Deaths
			   Recovered
		       Active                    
		       Combined_Key  $
		 	;
		%end;
		/* read the old format */
		%else %if &typer=2 %then %do;
		 	input
				Province_State  $
				Country_Region  $
				Last_Update
				Confirmed
				Deaths
				Recovered
			;
		%end;
		
		/* apply leading zeros - 00000 picture to fips */
		fips = put(fipstemp,fipsfive.);
		
		drop_filedate="&outdataset";
		

		AUG_STATE			= province_state;
		AUG_country			= country_region;
		

	 	
	 	AUG_filedate		= mdy(substr("&outdataset",5,2),substr("&outdataset",7,2),substr("&outdataset",1,4));
		AUG_PlotDate		= cats(location,":",substr(filedate,5,2),"/",substr(filedate,7,2));	 	
		
	/* Data Correction */
		if country_region="UK" or province_state="UK" or province_state="United Kingdom" then do;
			AUG_COUNTRY	= 'United Kingdom';
			AUG_STATE	= 'United Kingdom';

		end;
		if country_region = "Mainland China" 	then AUG_Country="China";
		if Country_region = "Gambia, The" 		then AUG_Country="The Gambia";
		
		if province_state = "Chicago" then  AUG_STATE="Chicago, IL"; 
		
		if Country_region = "Austria" and province_state="None" 	then AUG_STATE="";
		if Country_region = "Iraq" 	and province_state="None" 		then AUG_STATE="";
		if Country_region = "Lebanon" and province_state="None" 	then AUG_STATE="";
		if Country_region = "France" and province_state="France" 	then AUG_STATE="";
		
	/* End Data Correction */
		
		if province_state='' or province_state=country_region then AUG_ROLLUP="National";
	 	else if index(province_state,",") > 1 or index(aug_state,",") > 1 or fips~='NONE' then AUG_ROLLUP="Local";
	 	else AUG_ROLLUP='Regional';
	 	
		drop drop_filedate;
	
	run;  
	%if &typer=2 %then %do;
		%if &counter=1 %then %do;
			data JHU_Legacy;
				set JHU&outdataset;
			run;
		%end;
		%else %do;
			data JHU_Legacy;
				set JHU_Legacy JHU&outdataset;
			run;
		%end;
	%end;
	%else %if &typer=1 %then %do;
		%if &counter=1 %then %do;
			data JHU_current;
				set JHU&outdataset;
			run;
		%end;
		%else %do;
			data JHU_current;
				set JHU_current JHU&outdataset;
				
			run;
		%end;
	%end;
	
%mend LoadCSV;


%let covidpath=/covid19data/csse_covid_19_data/csse_covid_19_daily_reports;
%let progpath=/covid_analysis/sas;
%let outputpath=/covid_analysis/graphs/;
%let rc = %sysfunc(dlgcdir("&covidpath"));

proc datasets library=WORK kill; run; quit;
%global adjust_note	adjust_date adjust_confirmed adjust_deaths;

/* %put NOTE: ***********************; */
/* %put NOTE: UPDATING GIT REPOSITORY; */
/* %put NOTE: ***********************; */
/*  */
/* https://go.documentation.sas.com/?docsetId=lefunctionsref&docsetTarget=n1mlc3f9w9zh9fn13qswiq6hrta0.htm&docsetVersion=9.4&locale=en */
/*  */
/* data _null_; */
/* 	version = gitfn_version();   put "NOTE: lib2git version: " version; */
/*    * n = GITFN_DIFF("/covid19data"); */
/*    * put n=; */
/* run; */
/*  */
/* data _null_; */
/*     n = GITFN_status("/covid19data"); */
/*     put n=; */
/* run; */
/* data _null_; */
/* 	rc= GITFN_PULL("/covid19data"); */
/* run; */
/* %put NOTE: ***********************; */
/* %put NOTE: END UPDATING GIT REPO; */
/* %put NOTE: ***********************; */



proc format;
	picture fipsfive low-high= "99999"
					 .= 'NONE';
run;

/* data _null_; */
/* a=put(1,fipsfive.); */
/* b=put(333,fipsfive.); */
/* c=put(55555,fipsfive.); */
/* f=put(.,fipsfive.); */
/* put a= b= c= f=; */
/* run; */

options mlogic mprint;
data _null_;
	legacy_count=0;
	current_count=0;
	handle=dopen('covid19');
	if handle > 0 then do;
		count=dnum(handle);
		do i=1 to count;
			memname=dread(handle,i);
			filepref = scan(memname,1,'.');
			fileext  = scan(memname,2,".");
			if fileext = "csv" then do;
				filedate = compress(cats(scan(filepref,3,'-'),scan(filepref,1,'-'),scan(filepref,2,'-')));
				if filedate <= '20200321' then do; /* this accounts for JHU infile structure change */
					legacy_count+1;
					call execute(cats('%LoadCSV(&covidpath/',memname,',',filedate,',',2,',',legacy_count,')'));
				end;
				else do;
					current_count+1;
					call execute(cats('%LoadCSV(&covidpath/',memname,',',filedate,',',1,',',current_count,')'));
				end;
			end;
		end;
	end;
	rc=dclose(handle);
run;

%let rc = %sysfunc(dlgcdir("&outputpath"));

/* this macro makes it possible to recalcuate the summaries after new data is added manually */
/* Create the full dataset */
proc sql;
	create table JHU_CORE_TS as
	
		select
			 fips
			,aug_filedate
			,Last_Update
			,aug_state
			,aug_country
			,aug_rollup
			,sum(confirmed) as confirmed
			,sum(deaths) as deaths
			,sum(recovered) as recovered
		from jhu_current
			group by fips
			,aug_state
			,aug_country
			,aug_rollup
			,aug_filedate
			,Last_Update
	UNION
		select
			 fips
			,aug_filedate
			,Last_Update
			,aug_state
			,aug_country
			,aug_rollup
			,sum(confirmed) as confirmed
			,sum(deaths) as deaths
			,sum(recovered) as recovered
		from jhu_legacy
			group by fips
			,aug_state
			,aug_country
			,aug_rollup
			,aug_filedate
			,Last_Update
	;

	create table JHU_CORE_LOC as
		select
			 fips
			,aug_state
			,aug_country
			,aug_rollup
			,max(confirmed) as confirmed
			,max(deaths) as deaths
			,max(recovered) as recovered
		from JHU_CORE_TS
			group by
			 aug_country
			,aug_rollup	
			,aug_state
			,fips
	;

quit;

proc print data=jhu_core_loc; run;

proc sql; 
	select
		,aug_country
		,aug_rollup	
		,sum(confirmed) as confirmed
		,sum(deaths) as deaths
		,sum(recovered) as recovered
		from JHU_CORE_TS
		
		group by
			 aug_country
			,aug_rollup	
			;
quit;

proc print data=jhu_core_loc;
	where	
	aug_country="US"
	and 
	aug_rollup="Regional";
run;

/* Delete all the daily files */
proc contents data=work._all_ out =workds ;run;
proc sql noprint; 
	select distinct memname into :delds separated by ' ' 
		from workds 
		where substr(memname,1,5)='JHU20'
	; 
quit;
%put NOTE: Deleteing &delds; 
proc delete data=&delds workds ; run;



















































