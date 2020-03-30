*****************************************************************
***** GraphLocation.sas
***** pulls and prepares csv data from covid19 and analyzes  
***** data
*****************************************************************;

proc sql;
	create table CountyLevel as
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
		from jhu_current as jhu
			left join 
			 FIPS.POPULATION_ESTIMATES as census
			on jhu.fips = census.fips_join
		where fips is not null 
		group by
			 fips
			 ,location
			,filedate
			,stname
			,ctyname
		order by fips,filedate;
quit;


/*****************************************************************************************/
/* Sanity Checkpoint */
/* look for possible errors. I think it is sometimes reasonable to have multiple updates, 
		but probably not a lot... lets check*/
	data errors_to_check;
		set countylevel;
		if freq > 1 then do;
			put fips= location= census_state= census_county=;
			output;
		end;
	run;
	proc sql;
		select * 
			from jhu_current 
			where fips in (
				select distinct fips 
					from errors_to_check
				) 
			order by fips,filedate;
	quit;
/*****************************************************************************************/

data County_Most_Recent;
	set countylevel;
	label plotlabel="Location";
	plotlabel=cats(census_county,", ",census_state);
	log_confirmed=log(confirmed);
	log_population_estimate=log(population_estimate);
	by fips filedate;
	if last.fips and last.filedate then output;
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
	*%let var=confirmed_percapita_rank;
	%let var=confirmed_rank;
	select &var
			, count(*) as freq 
	from county_ranks 
	group by &var ; 
quit;

proc sort data=County_Ranks;
	by descending confirmed_percapita;
run;

%let rc = %sysfunc(dlgcdir("&outputpath")); %put RC=&rc;


proc reg data=county_ranks(where=(confirmed_rank>0));
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
run;
proc sort data=regvals; by population_estimate; run;
options orientation=landscape papersize=(16in 16in) ;
ods graphics on / reset width=15in height=15in  imagemap outputfmt=svg;
*ods listing gpath="&outputpath" device=png;
ods html close;ods rtf close;ods pdf close;ods document close; 
ods html5 file="CountyPerCapita.html" gpath= "&outputpath" device=svg options(svg_mode="inline");
	title US Counties;
	footnote 'Data Source: Johns Hopkins University - https://github.com/CSSEGISandData/COVID-19';
*	proc sgplot data=county_Ranks(where=(confirmed > 10 and deaths > 5 and population_estimate > 0))  noautolegend;
	proc sgplot data=regvals(where=(confirmed_rank>0))  noautolegend;
		bubble x=population_estimate 
			   y=confirmed 
			   size=deaths_rank / 
			datalabel=plotlabel 
			fillattrs=(color=CX004df8 transparency=0.75) 
			datalabelpos=center 
			datalabelattrs=(size=6 color=CX000000) 
			bradiusmin=5 
			bradiusmax=20
			tip=(plotlabel confirmed deaths population_estimate confirmed_percapita deaths_percapita);
		series y=p_confirmed x=population_estimate  ;
		series y=ucl_confirmed x=population_estimate  ;
		series y=lcl_confirmed x=population_estimate  ;
		series y=uclm_confirmed x=population_estimate  ;
		series y=lclm_confirmed x=population_estimate  ;
		xaxis grid type=log;
		yaxis grid type=log;
	run;
ods html5 close;
ods graphics / reset;
	
	
	
	


