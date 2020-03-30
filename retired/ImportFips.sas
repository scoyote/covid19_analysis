 
 filename all_fips "/covid_analysis/data/all-geocodes-v2018.csv";
 filename st_fips "/covid_analysis/data/state-geocodes-v2018.csv";

 data FIPS.ALL_FIPS    ;
	infile all_fips delimiter = ',' MISSOVER DSD  firstobs=2 ;
	 
	informat "Summary Level"N $5. ;
	informat "State Code (FIPS)"N $5. ;
	informat "County Code (FIPS)"N $5. ;
	informat "County Subdivision Code (FIPS)"N $5. ;
	informat "Place Code (FIPS)"N $5. ;
	informat "Consolidtated City Code (FIPS)"N $5. ;
	informat "Area Name (including legal/stati"N $100. ;
	format "Summary Level"N $5. ;
	format "State Code (FIPS)"N $5. ;
	format "County Code (FIPS)"N $5. ;
	format "County Subdivision Code (FIPS)"N $5. ;
	format "Place Code (FIPS)"N $5. ;
	format "Consolidtated City Code (FIPS)"N $5. ;
	format "Area Name (including legal/stati"N $50. ;	
	input
		 "Summary Level"N $
		 "State Code (FIPS)"N $
		 "County Code (FIPS)"N $
		 "County Subdivision Code (FIPS)"N $
		 "Place Code (FIPS)"N $
		 "Consolidtated City Code (FIPS)"N $
		 "Area Name (including legal/stati"N  $
	 ;
 run;
 
data FIPS.STATE_GEOCODES    ;
	infile st_fips delimiter = ',' MISSOVER DSD  firstobs=2 ;

	 informat Region $5. ;
	 informat Division $5. ;
	 informat "State (FIPS)"N $5. ;
	 informat Name $100. ;
	 format Region $5. ;
	 format Division $5. ;
	 format "State (FIPS)"N $5. ;
	 format Name $50. ;
	input
        Region $
        Division $
        "State (FIPS)"N $
        Name  $
	;
run;
 
 
 proc sql;
	create table  FIPS.FIPS_DB as
		select  
			PLACES.'Area Name (including legal/stati'n as area_name,
			PLACES.'Consolidtated City Code (FIPS)'n,
			PLACES.'County Code (FIPS)'n,
			PLACES.'County Subdivision Code (FIPS)'n,
			PLACES.'Place Code (FIPS)'n as place_code,
			PLACES.'State Code (FIPS)'n as state_code,
			catx(PLACES.'State Code (FIPS)'n,PLACES.'Place Code (FIPS)'n) as FIPS_join,
			PLACES.'Summary Level'n,
			STATES.Division,
			STATES.Name as state_name,
			STATES.Region,
			STATES.'State (FIPS)'n
		from  FIPS.ALL_FIPS as places inner join FIPS.STATE_GEOCODES as states
		on places.'State Code (FIPS)'n =  states.'State (FIPS)'n
	;
quit;
 
 