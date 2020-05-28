
data _trajectories;
	set state_trajectories;*(where=(province_state="South Carolina"));
	weekNumber=week(filedate,'u');
run;
proc sort data=_trajectories;
	by province_state filedate weeknumber;
run;
data _firstdays; set _trajectories;
	by province_state weeknumber;
	keep province_state filedate weeknumber dayofweek;
	dayofweek=put(weekday(filedate),downame3.);
	put  province_state filedate weeknumber first.province_state= first.filedate= first.weeknumber=;
	if first.weeknumber and dayofweek = 'Sat'; /*(week(fd,'u'))*/
run;

proc sql;
	create table _t1 as
		select province_state
		,weeknumber
		,sum(confirmed) as confirmed 	format=comma12.
		,sum(deaths) as deaths 			format=comma12.
		,count(*) as frequency
		from _trajectories
		group by 
		province_state
		,weekNumber
		;
		
	create table _t2 as	
		select a.*,b.filedate,b.dayofweek 
		from _t1 a
		inner join _firstdays b
		on a.province_state=b.province_state 
			and a.weekNumber=b.weekNumber
		order by province_state, filedate,weeknumber
		;
quit;


proc expand data=_t2 out=_expanded;
	id filedate;
	by province_state ;
	convert confirmed	= dif1_confirmed / transout=(dif 1);
	convert deaths		= dif1_deaths 	 / transout=(dif 1);
run;
data _expanded; set _expanded;
	new_confirmed=floor(dif1_confirmed);
	new_deaths=floor(dif1_deaths);
	format new_confirmed  new_deaths comma12.;
	label new_confirmed = "New Cases";
	label new_deaths = "New Deaths";
run;

ods graphics / reset=all height=4in width=7.5in;
proc sgplot data=_expanded;
	by province_state;
	series x=filedate y=new_confirmed 	/ markers markerattrs=(symbol=circlefilled color=darkblue) group=province_state groupdisplay=cluster ;
	series x=filedate y=new_deaths	 	/ markers markerattrs=(symbol=circlefilled color=darkred ) group=province_state groupdisplay=cluster y2axis	  ;
	
run;
quit;

data _s1;
	set _expanded;
	keep province_state filedate cat value;
	cat="Cases";
	value=new_confirmed;
run;
data _s2;
	set _expanded;
	keep province_state filedate cat value;
	cat="Deaths";
	value=new_deaths;
run;
data _stacked; set _s1 _s2;
run;
proc sort data=_stacked; by province_state filedate cat; run;
proc sgplot data=_stacked;
	by province_state;
	vbar filedate /response=value group=cat 	;
run;
quit;
proc sgplot data=_stacked(where=(value>0));
	by province_state;
	series x=filedate y=value /group=cat;
run;
quit;

proc sgplot data=_trajectories;
	by province_state;
	vbox dif1_confirmed / category=filedate group=type groupdisplay=cluster
    lineattrs=(pattern=solid) whiskerattrs=(pattern=solid); 
  	xaxis display=(nolabel);  
run;
 
 