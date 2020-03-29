%macro LoadCSV(infilepath,outdataset,typer,counter);

	data JHU&outdataset    ;
		   infile "&infilepath" 
		   delimiter = ',' 
		   MISSOVER 
		   DSD
		   lrecl=32767 
		   firstobs=2 ;
		informat FIPS best32. ;
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
		format FIPS best12. ;
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
		%if &typer=1 %then %do;
			input
			   FIPS
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
	 	filedate="&outdataset";
	 	if province_state = "" then Location=country_region;
		else location = cats(province_state," - ",country_region);
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

