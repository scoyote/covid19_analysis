


*WORK.JHU20200327;
proc sort data=jhu_current out=allcompose;
	by province_state filedate;
run;



/* fix some errors in the data */
data allcompose;set allcompose;
	if province_state="Californ" then province_state="California";
	if province_state="New Jers" then province_state="New Jersey";
	if province_state="Washingt" then province_state="Washington";
	if province_state = "" then province_state=country_region;
run;
	
proc means data=allcompose noprint;
	class province_state filedate / order=data;
	var confirmed deaths;
	output out=allcompose_summary
		(where=(_type_ = 3) )
		sum(confirmed deaths)=confirmed deaths;
	label confirmed="Confirmed Infections"
		  deaths="Deaths"
		  province_State='Location';
run;

proc sql;
	*select distinct upcase(country_region) from jhu_current where upcase(country_region) like "GER%";
	select * from allcompose_summary where upcase(province_state) like "GERMANY";
quit;
proc sort data=allcompose_summary;by province_state filedate;run;
data plotstate;
	set allcompose_summary;
	keep province_state;
	by province_state filedate;
	if last.province_state and last.filedate and confirmed>2000 and deaths>50 then output;
run;

proc sql; select distinct province_state into :states separated by '","' from plotstate; quit;


ods graphics / reset width=12in height=12in imagemap;
proc sgplot data=allcompose_summary;
	scatter x=Confirmed y=Deaths / group=province_state
		datalabel=province_state 
		markerattrs=(size=7) 
		datalabelattrs=(size=5) 
		transparency=0.25;
	series x=Confirmed y=Deaths  / group=province_state;
	xaxis grid type=log;
	yaxis grid type=log;
	where province_state in ("&states");
run;

ods graphics / reset;