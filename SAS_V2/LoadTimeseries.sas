proc datasets library=WORK kill; run; quit;

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

proc print data=confirmed_global_ts;
where country_region="Canada";
run;

%buildDatasets(US,fips);
%buildDatasets(global,location);

proc datasets library=work;
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
		CBSA_Title 			$50.
		MSA_Title 			$25.
		CSA_Title 			$25.
		County_equivalent 	$25.
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
	state_fips=fipstate(stfips_cd);
run;

/*
proc sql; 
	insert into US_AUGMENTEd 
			(province_state, filedate, confirmed, deaths) 
		values("Georgia", '13APR2020'd,13621,480)
	;
quit;
*/	

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






















