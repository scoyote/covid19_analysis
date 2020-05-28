proc datasets library=WORK kill nodetails nolist; run; quit;

proc format;
	picture fipsfive low-high= "99999"
					 .= 'NONE';
run;
%let covidpath=/covid19data;
%let progpath=/covid_analysis/sas_v2;
%let outputpath=/covid_analysis/sas_v2/graphs;

libname covid '/covid19data';   
libname fips "/covid_analysis/data";        
filename covid19 "&covidpath";

%include "&progpath./MACROS.sas";

*%UpdateJHUGit;
%loadTS_Global(type=confirmed);
%loadTS_Global(type=deaths);
%loadTS_Global(type=recovered);
%loadTS_US(type=confirmed);
%loadTS_US(type=deaths);
%loadICU;
%loadCensus;
%JhuXW;

/* proc print data=confirmed_global_ts; */
/* where country_region="Canada"; */
/* run; */

%buildDatasets(US,fips);
%buildDatasets(global,location);

proc datasets library=work noprint nodetails;
	delete  
		CONFIRMED_US_TS  
		CONFIRMED_GLOBAL_TS
		DEATHS_GLOBAL_TS  
		DEATHS_US_TS;
quit;

/********************************************************************/
/*****	Augment US Data with Census and hospital metadata		*****/
/********************************************************************/
proc sort data=us_joined; by fips; run;
proc sort data=FIPS.CBSA_COUNTY_CROSSWALK; by fipsjoin; run;
proc sort data=FIPS.icu_beds; by fipsjoin; run;
proc sort data=FIPS.population_estimates; by fips_join; run;

data US_Augmented;
	format 
		uid 				best12.
		fipsjoin 			$5.
		country_region 		$25.
		Province_State 		$25.
		combined_key 		$50.
		Filedate 			yymmdd10.
		confirmed 			comma12.
		deaths 				comma12.
		CBSA_Title 			$100.
		MSA_Title 			$100.
		CSA_Title 			$100.
		County_equivalent 	$100.
		State  				$25.
		State_Name 			$25.
		census2010pop 		comma12.
		popestimate2019 	comma12.
		hospitals 			comma12.
		icu_beds 			comma12.
	;
	merge us_joined (in=base rename=(fips=fipsjoin))
		  fips.cbsa_county_crosswalk (in=census keep=  FIPSjoin CBSA_Title  County_Equivalent  State  State_Name MSA_Title  CSA_Title)
		  fips.population_estimates (in=pop rename=(fips_join=fipsjoin) keep=fips_join census2010pop  POPESTIMATE2019 )
		  fips.icu_beds (in=icu keep=fipsjoin  HOSPITALS  ICU_BEDS);
	by fipsjoin;
	if base;
	Drop admin2 code3 iso2 iso3 lat long_;
	rename fipsjoin=fips;
	if substr(fipsjoin,1,3) in ('000') or substr(fipsjoin,1,1) in ('8' '9') then do;
		stfips_cd = substr(fipsjoin,4,2);
	end;
	else if substr(fipsjoin,1,2) ~= 'f1' then stfips_cd=25;
	else if substr(fipsjoin,1,2) ~= 'f2' then stfips_cd=29;
	else stfips_cd=substr(fipsjoin,1,2);
	if stfips_cd ~= '99' then state_fips=fipstate(stfips_cd);
run;


%create_trajectories;
