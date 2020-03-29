proc sql;
	select fips,location,province_state,country_region,filedate, count(*) as freq,sum(confirmed) as total_confirmed
	from jhu_current
	where upcase(location) like '%YORK%' 
	group by fips,location,province_state,country_region,filedate
	order by filedate;
quit;