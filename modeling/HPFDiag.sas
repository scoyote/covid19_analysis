libname pCovid '/repositories/covid19_analysis/SAS_V2/data';

proc sql;
	create table florida as
	select 
		province_state
		,reportdate
		,sum(confirmed) as totalcases
		,sum(deaths) as totaldeaths
		,sum(dailyconfirmed) as dailycases
		,sum(dailydeaths) as dailydeaths
	from pcovid.us_daily
	where province_state = "Florida"
	group by province_state, reportdate
	order by province_state, reportdate
;
quit;

proc hpfdiagnose
     data=florida holdout=7 back=7 seasonality=7  criterion=mape print=all rep=work.myrep;
   id reportdate interval=day;
   forecast dailycases;
   transform;
   esm method=bests;
   arimax p=(0:10)(0:2) q=(0:10)(0:2)  estmethod=ml ;
/*    combine method=average encompass=ols misspercent=25 hormisspercent=50; */
run;