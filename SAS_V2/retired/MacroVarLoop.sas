%macro testit(plotvariable);
	data _test;
		census2010pop = 1;
		icu_beds=10;
		hospitals=100;
		myanalysisvar=100;
		%local i next_var vars;
		%let vars= census2010pop icu_beds hospitals;	
		%do i=1 %to %sysfunc(countw(&vars));
		   %let next_var = %scan(&vars, &i);
		   %put [&i] [(&vars)] [&next_var];
		   %put Attempting:  &plotvariable._per_&next_var = &plotvariable / &next_var;
		   &plotvariable._per_&next_var = &plotvariable / &next_var;
		   put "NOTE: " &plotvariable._per_&next_var=;
		   output;
		%end;
	run;
%mend;
%testit(myanalysisvar);


proc print data=death_trajectories(where=(location='US'));
var filedate  MA7_confirmed MA7_deaths MA7_new_confirmed ma7_new_deaths ma7_new_deaths_per_census2010pop ma7_new_deaths_per_hospitals ma7_new_deaths_per_icu_beds;
run;