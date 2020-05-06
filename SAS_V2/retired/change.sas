/* %let procvar=province_state; */
/* %let level	=state; */
/* %let procvar=location; */
/* %let level	=global; */
/* proc expand data=&level._trajectories out=_global; */
/* 	id filedate; */
/* 	by &procvar; */ 
/* 	convert dif1_confirmed	= dif14_confirmed	/ transout=(movave 14); */
/* 	convert dif1_deaths		= dif14_deaths		/ transout=(movave 14); */
/* run; */
/*  */
/* data _plottemp; */
/* 	set _global; */
/* 	by &procvar filedate; */
/* 	if ~first.&procvar then do; */
/* 		lag_dif7_confirmed=lag(dif7_confirmed); */
/* 		dif = lag_dif7_confirmed-dif7_confirmed; */
/* 	end; */
/* 	if last.&procvar then output; */
/* run; */
/* proc sort data=_plottemp; by dif; run; */
/* proc print data=_plottemp; */
/* 	var &procvar */
/* 		confirmed */
/* 		deaths */
/* 		ma7_new_confirmed */
/* 		ma7_new_deaths */
/* 		dif1_confirmed */
/* 		dif1_deaths */
/* 		dif14_confirmed */
/* 		lag_dif7_confirmed */
/* 		dif */
/* 		dif14_deaths; */
/* run; */
/*  */
/* title;footnote; */
/*  */
/* proc sgplot noborder */
/* 	data=_global(where=(&procvar="New York")); */
/* 	vbar filedate /response=dif7_confirmed transparency=0.25; */
/* 	xaxis minor display=(noline) offsetmax=0 offsetmin=0 labelattrs=(size=15) valueattrs=(size=12); */
/* 	yaxis minor display=(noline) type=log labelattrs=(size=15) valueattrs=(size=12) LOGSTYLE=LOGEXPAND ; */
/* run; */

%macro plot_emerging(level,procvar,maxplots=20);
	
	data _plottemp;
		set _global;
		by &procvar filedate;
		if ~first.&procvar then do;
			lag_dif7_confirmed=lag(dif7_confirmed);
			dif = lag_dif7_confirmed-dif7_confirmed;
		end;
		if last.&procvar then output;
	run;
	proc sql noprint;
			select &procvar into :loc1-:loc&maxplots
			from _plottemp 
			order by dif ;
	quit;
	%do i=1 %to 2;*&maxplots;
		%put Working on &i of &maxplots: From PLOTlocS: "&&loc&i";
 		%plotstate(state="&&loc&i",level=state,numback=30); 
	%end;
	
%mend;

%plot_emerging(state,province_state);





