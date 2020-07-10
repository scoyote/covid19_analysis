proc sql noprint;
	create table ga100k as
		select 
		 combined_key
		,max(dif1_confirmed) as maxcases
		,max(dif1_deaths) as maxdeaths
		,max(census2010pop) as population
		,100000*max(dif1_confirmed)/max(census2010pop) as CasesPer100k
		,100000*max(dif1_deaths)/max(census2010pop) 	 as DeathsPer100k
		from fips_trajectories 
		where substr(fips,1,2)='13'
/* 		'13' */
			and filedate>'01jul20'd
		group by combined_key
	;
quit;

proc sort data=ga100k; by descending casesper100k; run;
proc print; run;