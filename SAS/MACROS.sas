
proc format;
	picture fipsfive low-high= "99999";
run;

%macro AddAdjustment(typer,date,conf,death);
	%if &typer=1 %then %do;
		%put Running: AddAdjustment(&typer,&date,&conf,&death);
		if filedate = "&date" then do;
			confirmed = &conf;
			deaths 	  = &death;
		end;
		%LET adjust_note=Adjusted for &date: Confirmed = &conf Deaths = &death;
	%end;
	%put note = &adjust_note;
%mend AddAdjustment;

%macro AddData(typer,loca,date,conf,death);
	%if &typer=1 %then %do;
		proc sql;
			insert into JHU_CORE_TS
				(location,filedate, confirmed, deaths) 
				values ("&loca",&date,&conf,&death);
		quit;
		%recalculate_JHU_Summary;
	%end;
%mend AddData;

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
		
		
		/* Data Correction */
		if country_region="UK" or province_state="United Kingdom" then do;
			Country_region='United Kingdom';
			province_state='';
		end;
		
		
	 	st_filedate="&outdataset";
	 	filedate=mdy(substr(st_filedate,5,2),substr(st_filedate,7,2),substr(st_filedate,1,4));
		format filedate yymmdd10.;
	 	label filedate="File Date";
	 	fips = put(fipstemp,fipsfive.);
	 	drop fipstemp;
	 	
	 	
	 	if province_state = "" then Location=cats("Nation:",country_region);
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

%macro create_jhu_summary;

	/* this macro makes it possible to recalcuate the summaries after new data is added manually */
	/* Create the full dataset */
	proc sql;
		create table JHU_current_TS as
			select
				 fips
				,location
				,province_state
				,country_region
				,filedate
				,sum(confirmed) as confirmed
				,sum(deaths) as deaths
				,sum(recovered) as recovered
			from jhu_current
				group by fips,location,province_state,country_region,filedate
		;
		create table JHU_LEGACY_TS as
			select
				 fips
				,location
				,filedate
				,province_state
				,country_region
				,sum(confirmed) as confirmed
				,sum(deaths) as deaths
				,sum(recovered) as recovered
			from jhu_legacy
				group by fips,location,province_state,country_region,filedate
		;
	quit;
	data JHU_CORE_TS;
		set JHU_LEGACY_TS JHU_CURRENT_TS;
	run;
	/* This summarizes the previous table to location, over dates */
	proc sql;
	create table JHU_CORE_TS_CENSUS_SUMMARY as
		select 
		     fips
		    ,location
			,stname as census_state
			,ctyname as census_county
			,filedate
			,count(*) as freq
			,sum(confirmed) as confirmed format=comma16. label="Confirmed Cases"
			,sum(deaths) as deaths format=comma16. label="Deaths"
			,max(census2010pop) as population_estimate format=comma16. label="2010 Census Population Estimate"
			,sum(deaths)/sum(confirmed) as emp_fatality_rate format=percent7.5 label="Fatality Rate"
			,sum(confirmed)/max(census2010pop) as confirmed_percapita format=percent7.5 label="Infections Per Capita"
			,sum(deaths)/max(census2010pop) as deaths_percapita format=percent7.5 label="Deaths Per Capita"
		from JHU_CORE_TS as jhu
			left join 
			 FIPS.POPULATION_ESTIMATES as census
			on jhu.fips = census.fips_join
		where fips is not null 
		group by
			 fips
			 ,location
			,stname
			,ctyname
			,filedate
		order by fips,location,filedate
			,stname
			,ctyname;
	quit;
%mend;
%macro recalculate_JHU_Summary;
	proc sql;
		create table JHU_CORE_LOC_CENSUS_ICU_SUMMARY as	
			select 
			     jhu.fips label="FIPS"
			    ,jhu.province_state
			    ,jhu.country_region
				,location label="Location"
				,pop.state label="State"
				,pop.county	label="County"		
				,filedate label="File Date"
				,confirmed label="Confirmed"
				,deaths label="Deaths"
				,recovered label="Recovered"
				,pop.census2010pop as population_estimate label="County Population"
				,deaths/confirmed as emp_fatality_rate format=percent7.5 label="Fatality Rate"
				,confirmed/pop.census2010pop as confirmed_percapita format=percent7.5 label="Infections Per Capita"
				,deaths/pop.census2010pop as deaths_percapita format=percent7.5 label="Deaths Per Capita"
				,case when hospitals=. then 0 else hospitals end as county_hospitals label="County Hospitals"
				,case when icu_beds =. then 0 else icu_beds  end as county_icu_beds  label="County ICU Beds"
				from(
					select 
						jhu.fips
						,location
						,county
						,state
						,filedate
						,confirmed
						,deaths
						,recovered
						,pop.census2010pop 
					from JHU_CORE_TS as jhu
					left join fips.population_estimates pop
					on jhu.fips=pop.fips_join
				)
			left join fips.ICU_BEDS icu
			on jhu.fips = icu.fips;

		create table JHU_CORE_TS_ICU_census as
			select 
				fips
				,location
				,filedate
				,sum(confirmed) as confirmed
				,sum(deaths) as deaths
				,sum(recovered) as recovered
				,max(population_estimate) as population_estimate label="2010 County Poputlation Estimate"
				,max(county_hospitals) as total_county_hospitals label="Total County Hospitals"
				,max(county_icu_beds) as total_county_icu_beds label="Total ICU Beds"
				,max(emp_fatality_rate) as emp_fatality_rate format=percent7.5 label="Fatality Rate"
				,max(confirmed_percapita) as confirmed_percapita format=percent7.5 label="Infections Per Capita"
				,max(deaths_percapita) as deaths_percapita  format=percent7.5 label="Deaths Per Capita"
			from JHU_CORE_LOC_CENSUS_ICU_SUMMARY
				group by 
					fips
					,location
					,filedate
				order by  
					fips
					,location
					,filedate
			;
		create table JHU_CORE_LOC_ICU_Census as
			select
				 fips
				,location
				,county
				,sum(confirmed) as confirmed
				,sum(deaths) as deaths
				,sum(recovered) as recovered
				,max(population_estimate) as population_estimate label="2010 County Poputlation Estimate"
				,max(county_hospitals) as total_county_hospitals label="Total County Hospitals"
				,max(county_icu_beds) as total_county_icu_beds label="Total ICU Beds"
				,max(emp_fatality_rate) as emp_fatality_rate format=percent7.5 label="Fatality Rate"
				,max(confirmed_percapita) as confirmed_percapita format=percent7.5 label="Infections Per Capita"
				,max(deaths_percapita) as deaths_percapita  format=percent7.5 label="Deaths Per Capita"

			from JHU_CORE_LOC_CENSUS_ICU_SUMMARY
				group by
					fips
					,county
					,location
				order by 
					 fips
					 ,county
					 ,location
			;

		create table JHU_CORE_LOC_MSA_ICU as	
		select 
			jhu.*
			,case when cbsa.CSA_TITLE='' 
				then cats(
					case when jhu.county='' 
						then "Unassigned" 
						else jhu.county
						end
					,",",location) 
				else cbsa.CSA_TITLE 
				end as CSA_Title_Augmented
		from  JHU_CORE_LOC_ICU_CENSUS JHU
		left join work.CBSA_County_crosswalk cbsa
			on jhu.fips = cbsa.fipsjoin
			where scan(location,2,'-') = 'US'
		;
	quit;
%mend;


%macro setmax(dataclause,whereclause,additionalvars=);
	proc means data=&dataclause(where=(&whereclause)) noprint;
		var confirmed deaths;
		output out=tmeans max(confirmed deaths) =confirmed deaths;
	run;
	data _null_; 
		set tmeans;
		call symput("maxconfirmed",confirmed);
		call symput("maxdeaths",deaths);
	run;
	%put [&maxconfirmed, &maxdeaths];
	proc sql; drop table tmeans; quit;
%mend setmax;


%macro PlotInd(prex,loca,sufx,ta=0,dt=0,ac=0,ad=0,jt=0,jf=0,jc=0,jd=0);
	/* this sloppy way to call a funciton is not optimal - i will fix later */
	%let prefix=&prex;
	%let pvs=&loca;
	%let suffix=&sufx;
	
	/*
	proc sql; 
	select * from jhu_icu_timeseries where upcase(location) like "%GERM%";
	quit;
	*/
	/**********************************/
	/********** ADJUSTMENTS ************/
	/**********************************/
		%let adjust_type=&jt; /*set to 0 for no adjustment */
		%let adjust_date=&jf;
		%let adjust_confirmed=&jc;*3032;
		%let adjust_deaths=&jd;*102;
		%let adjust_note=;
		/* THIS WILL RESULT IN DUPLICATE FOR MULTIPLE RUNS WITH add_typer=1!!! */
		/* Run once with 1, then set to 0 */
		%let add_typer=&ta;
		%let add_date=&dt;
		%let add_confirmed=&ac;
		%let add_deaths=&ad;

	/***************************************/
	/* Passed in from runner, or set here  */
	/* %let pvs=Georgia;%let suffix='-US'; */
	/***************************************/
	data _null_; 
		call symput("region_name",compress("&pvs")); 
		call symput("location",cats("&prefix.&pvs.&suffix"));
	run;
	
	%put NOTE: Running &region_name [&prefix, &pvs, &suffix] for "&location";
	
	/* this is a stub that will add data from the runner program*/
/* 	%AddData(&add_typer,&location,&add_date,&add_confirmed,&add_deaths); */
	
	proc sql;
		create table temp_summary as
				select 
					 location
					,filedate
					,sum(confirmed) as confirmed
					,sum(deaths) as deaths
					,sum(recovered) as recovered
					,max(population_estimate) as population_estimate label="2010 County Poputlation Estimate"
					,max(county_hospitals) as total_county_hospitals label="Total County Hospitals"
					,max(county_icu_beds) as total_county_icu_beds label="Total ICU Beds"
					,max(emp_fatality_rate) as emp_fatality_rate format=percent7.5 label="Fatality Rate"
					,max(confirmed_percapita) as confirmed_percapita format=percent7.5 label="Infections Per Capita"
					,max(deaths_percapita) as deaths_percapita  format=percent7.5 label="Deaths Per Capita"
				from JHU_CORE_LOC_CENSUS_ICU_SUMMARY
				where location="&location"
				group by 
					location
					,filedate
				order by  
					location
					,filedate
				;
	quit;
	data &region_name._summary;
		set temp_summary;
		/* add adjustment here */
		%AddAdjustment(&adjust_type,&adjust_date,&adjust_confirmed,&adjust_deaths);
		dif_Confirmed = confirmed-lag(confirmed);
		dif_deaths = deaths-lag(deaths);
		label confirmed="Number of Confirmed Infections";
		label deaths = "Number of Deaths";
		label filedate = "Date of Report";
		label dif_confirmed = "New Cases";
		label dif_deaths="New Deaths";
		format confirmed comma11. deaths comma11.;
	run;
	
	proc sql;
		create table plotstack as
		(select filedate,"Confirmed" as lab, confirmed as stack from &region_name._summary)
		union
		(select filedate,"Deaths" as lab, deaths as stack from &region_name._summary)
		order by lab, filedate;
	quit;
	
	data attrmap;
		retain id "myid";
		informat value $10.;
		value="Confirmed"; fillcolor='CX6599C9'; linecolor='black'; output;
		value="Deaths"; fillcolor='CXEDAF64'; linecolor='black'; output;
	run;
	
	proc sort data=&region_name._summary; by filedate; run;
	
	options orientation=landscape papersize=(8in 5in) ;
	ods graphics on / reset width=8in height=5in  imagemap outputfmt=svg;
	ods html close;ods rtf close;ods pdf close;ods document close; 
	ods html5 file="&outputpath./States/&pvs..html" gpath= "&outputpath/states/" device=svg options(svg_mode="inline");
		title "&PVS COVID-19 Situation Report";
		title2 "New Cases and New Deaths";
		%SetNote;
		footnote 'Data Source: Johns Hopkins University - https://github.com/CSSEGISandData/COVID-19';
		
		
		proc sgplot data=&region_name._summary nocycleattrs ;
			format filedate mmddyy5.
			   dif_confirmed comma10.
			   dif_deaths comma10.;
			vbar  filedate / response=dif_confirmed stat=sum ;
			vline filedate / response=dif_deaths stat=sum y2axis;
			yaxis ; 
			y2axis ;
			xaxis  valueattrs=(size=5) fitpolicy=rotatethin;
			keylegend / location=outside;
		run;	
		
		title "&PVS COVID-19 Situation Report";
		title2 "Prevalence and Deaths";
		%SetNote;
		footnote 'Data Source: Johns Hopkins University - https://github.com/CSSEGISandData/COVID-19';
		
	
		proc sgplot data=plotstack nocycleattrs dattrmap=attrmap;
			format filedate mmddyy5.
			   stack comma10.;
			label filedate="File Date"
				  stack="Value"
				  lab="Measure";
			vbar filedate / response=stack stat=sum group=lab transparency=.15 attrid=myid
			tip=(filedate lab stack) 
			tiplabel=("Date" "Type" "Value") 
			tipformat= (yymmdd10. $20. comma10.);
			yaxis ; 
			xaxis valuesformat=mmddyy5. valueattrs=(size=6) fitpolicy=rotatethin;
			keylegend / location=outside;
		run;
		
		proc sgplot data=&region_name._summary ;
			format filedate mmddyy5.
			   confirmed comma10.
			   deaths comma10.;
			scatter y=confirmed x=filedate  /
				FILLEDOUTLINEDMARKERS 
				MARKERFILLATTRS=(color='CX6599C9') 
				MARKEROUTLINEATTRS=(color='CX6599C9') 
				markerattrs=(symbol=CircleFilled color='CX6599C9');
			series y=confirmed x=filedate  	/ 
				lineattrs=(color='blue') 
				legendlabel=" ";
			scatter  y=deaths x=filedate 	/  
				FILLEDOUTLINEDMARKERS 
				MARKERFILLATTRS=(color='CXEDAF64') 
				MARKEROUTLINEATTRS=(color='CXEDAF64')  
				markerattrs=(symbol=CircleFilled color='cxedaf64' ) 
				y2axis ;
			series y=deaths x=filedate 		/ 
				y2axis lineattrs=(color='red') 
				legendlabel=" ";
			yaxis ; 
			y2axis ;
			xaxis type=discrete fitpolicy=rotatethin valueattrs=(size=5)	valuesformat=mmddyy5. valuesrotate=diagonal ;
			keylegend / location=outside;
		run;
	ods html5 close;
	ods graphics / reset;
	
	/* %let region=Nation:India; */ 
/* 	%let region=Florida-US;  */
	%let alpha=0.2; 
	%let pvar=Confirmed; 
	%let mpop=100000; 
	%let rate=0.5; 
	%let mid=10; 
	 
	proc sql noprint; 
		create table PreppedForNLIN as 
		select * 
		,monotonic() as timeperiod 
		,monotonic() as idvar  
		from 
		(select  
			 filedate 
			,location 
			,sum(confirmed) as confirmed 
			,sum(deaths) as deaths 
			from JHU_CORE_TS 
			where location like "&location" 
			group by filedate,location 
		)	order by filedate,location 
		; 
		proc sql noprint; select max(timeperiod), max(filedate),min(filedate) into :maxtime,:maxdate,:mindate from PreppedForNLIN; 
	quit; 
	 
	%put NOTE: We found for &region_name that the last filedate was [&mindate,&maxdate] and the last timeperiod was &maxtime; 
	 
	/* Run nonlinear curve fitting - save the model out for forecasting */ 
	%let alphalab=%sysevalf(100*(1-&alpha)); %put [&alphalab];  
	/* ods output ParameterEstimates=PE; /* Save the estimates in a dataset to draw in later */ 
	
	data addblank;
		x = put(&maxdate,yymmdd10.);
		format filedate yymmdd10.;
		do tx = 1 to 100 by 5;
			timeperiod = &maxtime+tx;
			filedate=intnx('day',&maxdate,tx); /* add datetime to the timeperiod*/
			predict=1; /*set the flag if a prediction*/
			output;
		end;
		drop tx;
	run;
	data scoringds;
		set PreppedForNLIN
			addblank;
		keep location timeperiod filedate confirmed deaths;
	run;
	options orientation=landscape papersize=(8in 5in) ;
	ods graphics on / reset width=8in height=5in imagemap outputfmt=svg;
	ods html close;ods rtf close;ods pdf close;ods document close; 
	ods html5 file="&outputpath./predictions/&region_name.%cmpres(&maxdate).html" gpath= "&outputpath/predictions/" device=svg options(svg_mode="inline");
		footnote 'Data Source: Johns Hopkins University - https://github.com/CSSEGISandData/COVID-19';	
		title "Logistic Growth Curve Model for &pvar of &region._name";
		footnote2 "Prediction Made from Data as of %sysfunc(putn(&maxdate,yymmdd10.))";
			
		ods table ParameterEstimates=PE;
		proc nlin
		   data=scoringds method=marquardt list noitprint maxiter=32000;
		   parms maxpop &mpop rate &rate mid &mid;                        
		   model &pvar = maxpop / (1 + exp(-rate*(timeperiod - mid)))  ;  
		   output out=ScoreOut predicted=Predicted
		   			lcl=Lower&alphalab.Confidence 
		   			ucl=Upper&alphalab.Confidence 
		   			lclm=Lower&alphalab.Predict 
		   			uclm=Upper&alphalab.Predict 
		   ;
		run;
		/* load the parameter estimates into macro variables */
		data _null_; set pe end=eofpe;
			if estimate < 0 then do; call symput(parameter,put(estimate,6.3)); end;
			else do; call symput(parameter,put(estimate,comma10.)); end;
		run;
		data _null_; call symput("midt",put(intnx('day',&mindate,&mid),yymmdd10.)); run;
		%put Lookforme: &maxpop &rate &mid &midt &mindate;
		
		proc sort data=scoreout; by timeperiod; run;
		proc sgplot data=scoreout noautolegend;
			format &pvar comma10.;
		   band x=filedate 
		   		lower=Lower&alphalab.Predict    
		   		upper=Upper&alphalab.Predict   / 
		   			fillattrs=(color='CX8789d4' transparency=0.85);   
		   scatter x=filedate y=&pvar /
				markerattrs=(color='blue' )
				tip		=(filedate &pvar deaths predicted timeperiod)
				tiplabel=("Date" "&pvar" "Deaths" "Prediction" "Forecast" "Time Period")
				tipformat=(yymmdd10. comma10. comma10. comma10.2 comma10.2 comma10.);                            
		   series x=filedate y=Predicted 	/ lineattrs=(color='red') ; 
		   xaxis grid; 
		   yaxis grid;
		   inset ('MAX' = "&maxpop"  'Rate' = "&rate"  "Midpoint" = "&mid" "MidDate" = "&midt") / border opaque; /* parameter estimates */
		run;
		
	ods html5 close;
	ods graphics / reset;
	
	proc delete data= scoringds
		addblank scoreout pe PreppedForNLIN &region_name._summary attrmap plotstack  temp_summary;
	quit;

%mend PlotInd;

%macro cleanupds;
	proc contents data=work._all_ out =workds ;run;
	proc sql noprint; select distinct memname into :delds separated by ' ' from workds where substr(memname,1,5)='JHU20'; quit;
	%put NOTE: Deleteing &delds; 
	proc delete data=&delds workds; run;
%mend;

 