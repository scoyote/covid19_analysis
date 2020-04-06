/* CROKER - This data set may be incorrect. 
	Need to find the original from Kaiser Family Foundation - ICU beds */
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
	fips = scan(put(fipstemp,fipsfive.),1,'.');
	
	drop fipstemp;
run;
 
 
 
 
 
 
 
 
 
 