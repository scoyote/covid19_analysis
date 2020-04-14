%colormac;
%GLOBAL SCOLORS;
%macro setcolors(howmany);
	%colormac;
	%let scolors=CX000000;
	%do col=1 %to &howmany;
		%let samcolor&col=%rgb(%eval(10+&col),%eval(10+&col),%eval(10+&col));	
		%let scolors=&scolors &&samcolor&col;
	%end;
%mend setcolors;


%setcolors(10);
%put &scolors;

proc print data=_plots(where=(plotseq<=&daysback and casepercapita_rank >= 7 and deaths>&mindeath))
;run;
proc rank data=cbsa_trajectories(where=(plotseq=1)) out=_cbsarank groups=10 ties=dense;
	var casepercapita caseperbed caseperhospital;
	ranks casepercapita_rank caseperbed_rank caseperhospital_rank;
run;
proc sql;
	create table _rankinput as
	select 
		 cbsa_title
		
		,census2010pop
		,icu_beds
		,casepercapita
		,caseperhospital
		,caseperbed
		,count(*) as freq
	from cbsa_trajectories
		where cbsa_title is not null
	group by 
		cbsa_title
	order by 
		 cbsa_title
	;
quit;


proc rank data=cbsa_trajectories out=_ranks;
	var 
proc print data=_sqltemp(obs=1000);
where casepercapita >  0.005;
run;