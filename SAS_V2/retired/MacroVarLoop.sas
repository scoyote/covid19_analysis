%macro testit;
	%local i next_var vars;
	%let vars= census2010pop icu_beds hospitals;	
	%do i=1 %to %sysfunc(countw(&vars));
	   %let next_var = %scan(&vars, &i);
	   %put [&i] [(&vars)] [&next_var];
	   
	%end;
%mend;
%testit;