*****************************************************************
***** GraphLocation.sas
***** pulls and prepares csv data from covid19 and analyzes  
***** data
*****************************************************************;



/*****************************************************************************************/
/* Sanity Checkpoint */
/* look for possible errors. I think it is sometimes reasonable to have multiple updates, 
		but probably not a lot... lets check*/
/* 	data errors_to_check; */
/* 		set countylevel; */
/* 		if freq > 1 then do; */
/* 			put fips= location= census_state= census_county=; */
/* 			output; */
/* 		end; */
/* 	run; */
/* 	proc sql; */
/* 		select *  */
/* 			from jhu_current  */
/* 			where fips in ( */
/* 				select distinct fips  */
/* 					from errors_to_check */
/* 				)  */
/* 			order by fips,filedate; */
/* 	quit; */
/*****************************************************************************************/
proc sort data = JHU_CORE_TS_CENSUS_SUMMARY out=temp; by fips filedate; run;
data County_Most_Recent;
	set temp;
	label plotlabel="Location";
	plotlabel=cats(census_county,", ",census_state);
	if confirmed>0 then log_confirmed=log(confirmed); else log_confirmed=.;
	if population_estimate>0 then log_population_estimate=log(population_estimate); else log_population_estimate=.;
	by fips  filedate;
	if last.fips  and last.filedate then output;
run;


proc rank data=county_most_recent out=County_Ranks groups=10 ties=dense;                               
	var confirmed 
		deaths 
		population_estimate 
		emp_fatality_rate 
		confirmed_percapita 
		deaths_percapita;                                                          
	ranks confirmed_rank 
		deaths_rank 
		population_estimate_rank 
		emp_fatality_rate_rank 
		confirmed_percapita_rank 
		deaths_percapita_rank;                                                      
run;

proc sql;
	%let var=confirmed_rank;
	select &var
			, count(*) as freq 
	from county_ranks 
	group by &var ; 
quit;

proc sort data=County_Ranks;
	by location filedate;
run;


proc sort data=County_Ranks;
	by descending confirmed_percapita;
run;

%let rc = %sysfunc(dlgcdir("&outputpath")); %put RC=&rc;


proc reg data=county_ranks(where=(confirmed_rank>0 ));
	model log_confirmed=log_population_estimate / alpha=.2 ;
	output out=regvals 
		predicted=p_log_confirmed 
		lcl=lcl_log_confirmed 
		ucl=ucl_log_confirmed  
		lclm=lclm_log_confirmed 
		uclm=uclm_log_confirmed
		;
run;
data regvals; set regvals;
	p_confirmed=exp(p_log_confirmed);
	ucl_confirmed=exp(ucl_log_confirmed);
	lcl_confirmed=exp(lcl_log_confirmed);
	uclm_confirmed=exp(uclm_log_confirmed);
	lclm_confirmed=exp(lclm_log_confirmed);
	label p_confirmed="Confirmed Prediction"
		  ucl_confirmed="Confirmed Prediction UCL"
		  lcl_confirmed="Confirmed Prediction LCL"
		  uclm_confirmed="Confirmed UCL"
		  lclm_confirmed="Confirmed LCL";
/* 	if confirmed <= ucl_confirmed and confirmed > lcl_confirmed then plotlabel=''; */
	if confirmed <= ucl_confirmed-(ucl_confirmed*0.5) and confirmed > lcl_confirmed+(lcl_confirmed*0.3) then delete;
	
run;

/*correct the series plots */
proc sort data=regvals; by population_estimate; run;

options orientation=landscape papersize=(24in 24in) ;
ods graphics / reset width=23.5in height=23.5in imagemap outputfmt=svg;
ods html close;ods rtf close;ods pdf close;ods document close; 
ods html5 
	body="&outputpath./percapita/CountyPerCapita.html" 
	gpath= "&outputpath/percapita/" 
	device=svg 
	options(svg_mode="inline");

	title "US Counties";
	title2 "Per Capita Confirmed Infections";
	footnote 'Data Source: Johns Hopkins University - https://github.com/CSSEGISandData/COVID-19';
	proc sgplot data=regvals(where=(confirmed_rank>0));
		bubble x=population_estimate 
			   y=confirmed 
			   size=deaths_rank / 
			datalabel=plotlabel
			fillattrs=(transparency=0.75) 
			datalabelpos=center 
			datalabelattrs=(size=6 ) 
			bradiusmin=5 
			bradiusmax=20
			tip=(plotlabel confirmed deaths population_estimate confirmed_percapita deaths_percapita filedate);
		series y=p_confirmed x=population_estimate  	/ lineattrs=(color='green') ;
		series y=ucl_confirmed x=population_estimate 	/ lineattrs=(color='orange')  ;
		series y=lcl_confirmed x=population_estimate  	/ lineattrs=(color='orange')  ;
		xaxis grid type=log;
		yaxis grid type=log;
	run;

ods html5 close;
ods graphics / reset;
	
	
	
	
proc delete data=temp County_Most_Recent county_ranks regvals; run;

