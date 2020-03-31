
%macro AddAdjustment(typer,date,conf,death);
	%if &typer=1 %then %do;
		%put Running: AddAdjustment(&typer,&date,&conf,&death);
		if filedate = "&date" then do;
			confirmed = &conf;
			deaths 	  = &death;
		end;
		%LET adjust_note=Adjusted for &date: Confirmed = &conf Deaths = death;
	%end;
	%put note = &adjust_note;
%mend AddAdjustment;

/* Define a macro for offset */
%macro offset ();
	%if %sysevalf(&respmin eq 0) %then
		%do;
			offsetmin=0 %end;

	%if %sysevalf(&respmax eq 0) %then
		%do;
			offsetmax=0 %end;
%mend offset;


%macro SetNote;
	%put NOTE: Adjust_note = &adjust_note;
	%if %length(&adjust_note)>0 %then  %do;
		title3 "&adjust_note";
	%end;
	%else %do;
		title3;
	%end;
%mend SetNote;



%macro LoadCSV(infilepath,outdataset,typer,counter);

	data JHU&outdataset    ;
		   infile "&infilepath" 
		   delimiter = ',' 
		   MISSOVER 
		   DSD
		   lrecl=32767 
		   firstobs=2 ;
		informat FIPS $5. ;
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
		%if &typer=1 %then %do;
			input
			   FIPS $
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
		plotlabel_date = cats(location,":",substr(filedate,5,2),"/",substr(filedate,7,2));

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

