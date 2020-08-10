/***** MACROS.sas *****/

%macro iterateARIMA(
		dataset			/* name of the dataset holding the time series */
		,datetime		/* name of the date variable */
		,catvar			/* name of the category variable */
		,target			/* time series target variable */
		,maxp			/* maximum AR parameter */
		,maxq			/* maximum MA parameter */
		,maxd			/* max differencing parameter */
		,method=ml		/* estimation method */
		,alpha=0.05		/* alpha value */
		);
	/* load the macro variable array with the distinct values in the category variable */
	proc sql noprint;
		select count(distinct &catvar) into :numcat from &dataset;
		select distinct &catvar into :cat1-:cat%cmpres(&numcat) from &dataset;
	quit;
	/* loop through the parameters, run an arima for each set, then save the results */
	%let loop=0;
	ods graphics off; 
	%do ci=1 %to &numcat;
		%do p=0 %to &maxp;
			%do q=0 %to &maxq;
				%do d=0 %to &maxd;
					%put NOTE: Executing &catvar=&&cat&ci (&ci of %cmpres(&numcat)): arima(&p,&d,&q) with alpha=&alpha using &method; 
					
					proc sql noprint; select max(&datetime) into :lastdate from &dataset(where=(&catvar="&&cat&ci"));quit;
					
					ods output OptSummary=itr;
					proc arima data=&dataset(where=(&catvar="&&cat&ci"));
						identify noprint var=&target(&d) alpha=&alpha ;
						estimate printall p=&p q=&q method=&method;
						forecast noprint id=&datetime  out=_fcst back=7 lead=9 ;
					run;
					%let msg=;
					data _null_; set itr;
						if label1 = "Warning Message" then call symput('msg',cvalue1);
					run;
					%let mape=.;
					data _null_; set _fcst end=eof;
						retain err 0;
						where &datetime > intnx('day',&lastdate,-7);
						err+abs(residual);
						if eof then call symput("mape",err/7);
					run;		
					data results; 
						%if &loop=1 %then %do;
							set results end = eof;
							output; 
							if eof then do;
						%end;
						length &catvar catvar target $50 message $200 p d q mape 8;
						&catvar="&&cat&ci";catvar="&catvar";target="&target";p=&p;q=&q;d=&d;mape=&mape;message="&msg"; 
						output;
						%if &loop=1 %then %do; end; %end;
					run;
					%let loop=1;
				%end;
			%end;
		%end;
	%end;
	
%mend iterateARIMA;



%macro GetandBuildJHU_Covid(
	 region	/* US or global */
	,type	/* confirmed or deaths */
	);
	
	 %let keeps=;
	%if &region=US %then %do;
		%if &type=confirmed %then %do;
		 	filename fname url 'https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_confirmed_US.csv';
		    %let sortkey=Province_state fips combined_key;
		    %let colset=('UID','COMBINED_KEY','COUNTRY_REGION',"province_state",'FIPS','ADMIN2','CODE3','ISO2','ISO3','LAT','LONG_');    
		    %let scolset=UID COMBINED_KEY COUNTRY_REGION province_state FIPS ADMIN2 CODE3 ISO2 ISO3 LAT LONG_;   
		%end;
	    %if &type=deaths %then %do;
	    	filename fname	url 'https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_deaths_US.csv';
	        %let sortkey=Province_state fips combined_key;
	        %let colset=('UID','POPULATION','COMBINED_KEY','COUNTRY_REGION',"province_state",'FIPS','ADMIN2','CODE3','ISO2','ISO3','LAT','LONG_');    
	        %let scolset=UID POPULATION COMBINED_KEY COUNTRY_REGION province_state FIPS ADMIN2 CODE3 ISO2 ISO3 LAT LONG_;    
	        %let keeps=POPULATION;
	    %end;
	%end;
    %else %if &region=GL %then %do;
    	%if &type=confirmed %then %do;
    		filename fname url 'https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_confirmed_global.csv';
    	%end;
    	%else %do;
			filename fname url 'https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_deaths_global.csv';
		%end;
        %let sortkey='COUNTRY/REGION'n 'Province/State'n;
        %let colset=('COUNTRY/REGION','Province/State','LAT','LONG');    
        %let scolset='COUNTRY/REGION'n 'Province/State'n LAT LONG;    
    %end;
	PROC IMPORT DATAFILE=fname DBMS=CSV OUT=WORK._IMPORT_TS replace  ; 
		GETNAMES=YES; 
		GUESSINGROWS=1500;
	run;
	filename fname clear;
	
	proc contents 
		data=_import_ts 
		out=_cont 
		noprint; 
	run;
	
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
	proc sort data=_import_ts; 
		by &scolset;
	run;
	proc transpose 
		 data	= _IMPORT_ts 
		 out	= _import_t 
		 prefix	= UpDate_t;
		var "&txcols"n;
		by &scolset;
	run;
	
	proc datasets library=work nolist nodetails ;
		modify _import_t;
		rename update_t1	= &type;
		rename _name_		= FileDate;
	quit;
	data _analysis_temp;
		set _import_t;
		format 
			reportdate 		mmddyy5. 
			&type			comma12.
			;
		reportdate=input(filedate,mmddyy10.);
		keep 
			&sortkey
			reportdate 
			&type
			&keeps;
	run;
	proc sort data=_analysis_temp; 
		by  &sortkey 
			reportdate ;
	run;
	proc expand data=_analysis_temp out=_tx;
	   by &sortkey;
	   id reportdate;
   			convert &type	= Daily&type / transout=(dif 1);
	run;
	/*brute force way to remove roundoff error in subtraction */
	data pcovid.&region._&type;
		set _tx;
		daily&type=int(daily&type);
	run;

	proc datasets library=work nodetails nolist; 
		delete 
			_tx
			_cont 
			_analysis_temp
			_import_t 
			_import_ts;
	QUIT;
	%if &region=GL %then %do;
		proc datasets library=pcovid nodetails nolist; 		
			modify &region._&type.; 
			rename 'COUNTRY/REGION'n = Country_Region;
			rename 'Province/State'n = Province_state;
		quit;
	%end;
%mend GetandBuildJHU_Covid;

%macro assembleCovidData(region);
	proc sql;
	    create table _&region._Daily as
	    	%if &region=US %then %do;
	        	select a.*, b.population, b.dailydeaths, b.deaths
	        %end;
	        %else %do;
	      		select a.*, b.dailydeaths, b.deaths  
	        %end;
	        from
	            pcovid.&region._CONFIRMED a 
	        inner join
	            pcovid.&region._DEATHS b
	        %if &region=US %then %do;
		        on a.fips=b.fips
		        and a.combined_key=b.combined_key
		        and a.province_state=b.province_state
		        and a.reportdate=b.reportdate
		        order by 
		             a.fips
		            ,a.province_state
		            ,a.combined_key
		            ,a.reportdate
	        %end;
	        %else %do;
		        on a.country_region=b.country_region
		        and a.province_state=b.province_state
		        and a.reportdate=b.reportdate
		        order by 
		             a.country_region
		            ,a.province_state
		            ,a.reportdate
		    %end;
	        ;
	        %if &region=GL %then %do;
	        	proc sort data=pcovid.worldpopulation; by country; run;
	        		
	        	data _GL_Daily;
	        		merge 	_gl_daily(in=a)
	        				pcovid.worldpopulation(in=b rename=(country=country_region) keep=country population);
	        		by country_region;
	        		if a;
	        	run;
	        %end;
	        
	quit;
	
	proc expand data=_&region._daily out=pcovid.&region._DAILY;
		%if &region=US %then %do;
	    	by fips province_state combined_key;
	    %end;
	    %else %do;
	        by country_region province_state;
	    %end;
	    id reportdate;
	    convert DailyConfirmed = MA7_Cases  / transout=(movave 7);
	    convert DailyDeaths    = MA7_Deaths / transout=(movave 7);
	run;
	
	%if &region=US %then %do;
		title US_DAILY Extract Characteristics;
		proc sql;
			select province_state
				,count(*) as freq format=12.
				,count(distinct fips) as freq_fips format=12.
				,count(distinct combined_key) as freq_combined_key format=12.
				,min(reportdate) as min_reportdate format=mmddyy10.
				,avg(reportdate) as mean_reportdate format=mmddyy10.
				,max(reportdate) as max_reportdate format=mmddyy10.
				,avg(dailyconfirmed) as avg_dailyconfirmed format=12.3
				,avg(dailydeaths) as avg_dailydeaths format=12.3
				,avg(population) as avg_population format=12.3
			from pcovid.us_daily
			group by province_state
			order by province_state;
		quit;
	%end;
	%else %if &region=GL %then %do;
		title GL_DAILY Extract Characteristics;
		proc sql;
			select country_region
				,count(*) as freq format=12.
				,count(distinct province_state) as freq_fips format=12.
				,min(reportdate) as min_reportdate format=mmddyy10.
				,avg(reportdate) as mean_reportdate format=mmddyy10.
				,max(reportdate) as max_reportdate format=mmddyy10.
				,avg(dailyconfirmed) as avg_dailyconfirmed format=12.3
				,avg(dailydeaths) as avg_dailydeaths format=12.3
				,avg(population) as avg_population format=12.3
			from pcovid.gl_daily
			group by country_region
			order by country_region;
		quit;
	%end;
	
	proc datasets library=work nodetails nolist ;
	    delete _&region._daily ;
	quit;
%mend assembleCovidData;

%macro plotregion(region,state,key=0,numback=30,gfmt=svg);
		%if &region=US %then %do;
			proc sql noprint;
				create table _graph as	
				select reportdate
					,province_state
					%if &key~=0 %then %do;,combined_key %end;
					,int(sum(sum(dailyconfirmed,0))) as dailyconfirmed format=comma12.
					,int(sum(sum(dailydeaths,0))) as dailydeaths format=comma12.
					,int(sum(sum(confirmed,0))) as confirmed format=comma12.
					,int(sum(sum(deaths,0))) as deaths format=comma12.
					,int(sum(sum(ma7_cases,0))) as ma7_cases format=comma12.
					,int(sum(sum(ma7_deaths,0))) as ma7_deaths format=comma12.
					,sum(sum(population,0)) as population format=comma12. label='Population'
					,int(sum(sum(ma7_deaths,0)))/int(sum(sum(ma7_cases,0))) as empirical_ma7_death_rate format=percent6.3
					,int(sum(sum(ma7_cases,0)))/sum(sum(population,0))*1e5 as cases_ma7_per100k format=comma12.3
					,int(sum(sum(ma7_deaths,0)))/sum(sum(population,0))*1e5 as deaths_ma7_per100k format=comma12.3
					,put(reportdate,DOWNAME3.) as fd_weekday
				from pcovid.us_daily
				where province_state="&state"
				%if &key~=0 %then %do; and combined_key=&key %end;
				group by province_state
				%if &key~=0 %then %do;,combined_key %end;
				,reportdate
				order by province_state
				%if &key~=0 %then %do;,combined_key %end;
				,reportdate
			;
		%end;
		%else %do;
			proc sql noprint;
				create table _graph as	
				select reportdate
					,country_region
					%if &key~=0 %then %do;,province_state %end;
					,int(sum(sum(dailyconfirmed,0))) as dailyconfirmed format=comma12.
					,int(sum(sum(dailydeaths,0))) as dailydeaths format=comma12.
					,int(sum(sum(confirmed,0))) as confirmed format=comma12.
					,int(sum(sum(deaths,0))) as deaths format=comma12.
					,int(sum(sum(ma7_cases,0))) as ma7_cases format=comma12.
					,int(sum(sum(ma7_deaths,0))) as ma7_deaths format=comma12.
					,int(sum(sum(ma7_deaths,0)))/int(sum(sum(ma7_cases,0))) as empirical_ma7_death_rate format=percent6.3
					,int(sum(sum(ma7_cases,0)))/sum(sum(population,0))*1e5 as cases_ma7_per100k format=comma12.3
					,int(sum(sum(ma7_deaths,0)))/sum(sum(population,0))*1e5 as deaths_ma7_per100k format=comma12.3
					,put(reportdate,DOWNAME3.) as fd_weekday
				from pcovid.gl_daily
				where country_region="&state"
				%if &key~=0 %then %do; and province_state=&key %end;
				group by  country_region
				%if &key~=0 %then %do;,province_state %end;
				,reportdate
			;
		%end;
		data _null_; set _graph end=eof;
			if eof then call symput("maxdate",reportdate);
		run;
		%let gsym		=circlefilled; 
		%let gsize		=5;
		
		data _null_ ;call symput("wordDte",trim(left(put("&sysdate9"d, worddatx32.)))); run;

		%if &key=0 %then %do; 
			%let title="&State - Overall";
		%end;
		%else %do;
			%let title=&key;
		%end
		title;footnote;
		%let overlayopts=%str(border=FALSE walldisplay=NONE height=4.5in width=7.5in xaxisopts=(label=" " timeopts=(tickvalueformat=mmddyy5.)) yaxisopts=(label="Confirmed") y2axisopts=(label="Deaths"));
		%let overlayopts2=%str(border=FALSE walldisplay=NONE height=4.5in width=7.5in xaxisopts=(label=" " timeopts=(tickvalueformat=mmddyy5.)) yaxisopts=(label="Cases per 100k (blue)") y2axisopts=(label="Empirical Death Rate (red)"));
		%let xaxisopts  =%str(xaxisopts=(griddisplay=Off display=(label ticks tickvalues) gridattrs=(color=BWH )  type=time timeopts=(interval=day tickvaluerotation=diagonal tickvaluefitpolicy=rotatethin splittickvalue=FALSE) ));
		%let yaxisopts  =%str(yaxisopts=(griddisplay=Off display=(label ticks tickvalues) gridattrs=(color=BWH)));
		proc template;
			define statgraph lattice;
			begingraph / designwidth=1632px designheight=960px ;
			
				discreteattrvar attrvar=dayatr1 var=fd_weekday attrmap='daycolor1';
				discreteattrvar attrvar=dayatr2 var=fd_weekday attrmap='daycolor2';

				entrytitle textattrs=(size=13)   "SARS-CoV-2 Situation Report &wordDte";
				entrytitle textattrs=(size=13)   &TITLE;
				entryfootnote "Data Source: Johns Hopkins University - https://github.com/CSSEGISandData/COVID-19 Data Updated: &sysdate";
				entryfootnote  "Showing the Last &numback Days" ;
				entryfootnote  textattrs=(size=7) halign=right "Samuel T. Croker - &sysdate9" ;
				layout lattice / border=FALSE pad=3 opaque=true rows=2 columns=2 columngutter=3;
					cell; 
						cellheader; entry "Cumulative Infections and Deaths" / textattrs=(size=10); endcellheader;
				      	layout overlay / &overlayopts &yaxisopts xaxisopts=(discreteopts=(tickvaluefitpolicy=rotatethin) display=(label ticks tickvalues)) y2axisopts=(display=(label ticks tickvalues));
				      		barchart  category=reportdate response=confirmed / stat=sum datatransparency=0.75;
							linechart category=reportdate response=deaths / stat=sum yaxis=y2 lineattrs=(thickness=2 color=darkred) datatransparency=0.6 smoothconnect=true;
				      	endlayout;
				    endcell;
				    
					cell; 
						cellheader; entry "Rates per 100,000 Population" / textattrs=(size=10); endcellheader;
				      	layout overlay /&overlayopts2 &xaxisopts &yaxisopts y2axisopts=(display=(label ticks tickvalues)) ;
				      		scatterplot	y=cases_ma7_per100k x=reportdate / yaxis=y markerattrs=(size=8 color=darkblue symbol=circlefilled) FILLEDOUTLINEDMARKERS=TRUE MARKERFILLATTRS=(color=darkblue) MARKEROUTLINEATTRS=(color=darkblue)	;
							seriesplot	y=cases_ma7_per100k x=reportdate / yaxis=y lineattrs=(thickness=2 color=darkblue)	smoothconnect=true;
							scatterplot	y=empirical_ma7_death_rate 	x=reportdate / yaxis=y2 markerattrs=(size=8 symbol=circlefilled) FILLEDOUTLINEDMARKERS=TRUE 	;
							seriesplot	y=empirical_ma7_death_rate 	x=reportdate /  yaxis=y2 lineattrs=(thickness=2 color=darkred) 	smoothconnect=true;
				      	endlayout;						 
				    endcell;
				    
					cell; 
						cellheader; entry "New Infections and Deaths" / textattrs=(size=10); endcellheader;
				      	layout overlay /&overlayopts &yaxisopts xaxisopts=(discreteopts=(tickvaluefitpolicy=rotatethin) display=(label ticks tickvalues)) y2axisopts=(display=(label ticks tickvalues));
				      		barchart    category=reportdate response=dailyconfirmed / stat=sum datatransparency=0.75 group=dayatr1 filltype=solid outlineattrs=(color=grey) ;
							scatterplot x=reportdate y=dailydeaths / yaxis=y2 FILLEDOUTLINEDMARKERS=TRUE group=dayatr2;
						endlayout; 
					endcell;
				    
					cell; 
						cellheader; entry "New Infections and Deaths - Seven Day Moving Average" / textattrs=(size=10); endcellheader;
				      	layout overlay /&overlayopts  &yaxisopts xaxisopts=(discreteopts=(tickvaluefitpolicy=rotatethin) display=(label ticks tickvalues)) y2axisopts=(display=(label ticks tickvalues));
				      		barchart  category=reportdate response=ma7_cases 	/ stat=sum datatransparency=0.75 group=dayatr1 filltype=solid outlineattrs=(color=grey);
							scatterplot x=reportdate 	y=dailydeaths 	/ yaxis=y2 FILLEDOUTLINEDMARKERS=TRUE group=dayatr2;
				      	endlayout;	
			      	endcell;
				endlayout;
			endgraph;
			end;
		run;
		proc sgrender 
			 data=_graph(where=(reportdate>=intnx('day',&maxdate,-&numback))) dattrmap=work.daycolormap template=lattice ;
		run;
%mend plotregion;







