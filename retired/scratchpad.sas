

proc sql;
	select 
	     jhu.fips
/* 		,fips_join */
/* 		,location */
/* 		,province_state */
/* 		,country_region */
		,filedate
		,stname as census_state
		,ctyname as census_county
		,count(*) as freq
		,sum(confirmed) as confirmed
		,sum(deaths) as deaths
		,max(census2010pop) as population_estimate
		,sum(confirmed)/max(census2010pop) as confirmed_percapita
		,sum(deaths)/max(census2010pop) as deaths_percapita
	from jhu_current as jhu
		left join 
		 FIPS.POPULATION_ESTIMATES as census
		on jhu.fips = census.fips_join
	where province_state='South Carolina' 
	group by
		 fips
/* 		,fips_join */
/* 		,location */
/* 		,province_state */
/* 		,country_region */
		,filedate
		,stname
		,ctyname
	order by fips,filedate;
quit;



proc sql;

select * from fips.population_estimates where fips_join='45063';

quit;

	
proc sql;
	select * from fips.population_estimates where stname="New York" and ctyname='Albany County';
	select * from jhu_current where fips = '36001' order by fips,filedate;
quit;

proc sql; select * from jhu_current where upcase(location) like '%GERMA%';
run;

proc sql; 
select _type_,count(*) as freq from allcompose_summary group by _type_ order by _type_;
select * from allcompose_summary where _type_ = 7 and location = 'Georgia-US';
quit;


proc print data=allcompose_summary(where=(location in ("&usstates"))); run;