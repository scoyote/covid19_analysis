data working;
	label
		fips ='FIPS'
		location = "Calculated Location"
		province_state = "Province/State" 
		country_region ="Country/Region"
		filedate = "File Date"
		last_update = "Last Update"
		confirmed = "Confirmed"
		deaths ="Deaths"
		recovered ="Recovered"
	;
	set jhu_current;
	keep fips location province_state country_region filedate last_update confirmed deaths recovered;
run;

/*
proc sql;
	select 
	fips
	,location
	,filedate
	,province_state
	,country_region
	,count(*) as freq 
	,sum(confirmed) as confirmed
	,sum(deaths) as deaths
	from working 
	where province_state='Florida'
	group by fips,location,filedate,province_state,country_region 
	order by fips,location,filedate,province_state,country_region;
quit;
*/


proc means data=allcompose noprint;
	class location filedate plotlabel_date/ order=data;
	var confirmed deaths;
	output out=allcompose_summary 
		(where=(_type_ = 7) )
		sum(confirmed deaths)=confirmed deaths;
	label confirmed="Confirmed Infections"
		  deaths="Deaths"
		  location='Location';
run;
