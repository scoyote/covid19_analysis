/* County to CBSA Crosswalk: Source: https://www.census.gov/programs-surveys/metro-micro/about/delineation-files.html */
/* https://www2.census.gov/programs-surveys/metro-micro/geographies/reference-files/2018/delineation-files/list1_Sep_2018.xls */
data WORK.CBSA_County_Crosswalk   ;
	
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

/* proc sql; */
/* select * from cbsa_county where fipsjoin =''; */
/* select fipsjoin, count(*) as freq from WORK.CBSA_County group by fipsjoin order by fipsjoin; */
/* select * from cbsa_county where fips_state_code='45'; */
/* quit; */








