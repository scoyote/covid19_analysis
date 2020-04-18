

proc print data=store.model_final;

 var ScenarioNameUnique ScenarioIndex Scenarioname  ModelType DATE DAY
  S_N
  E_N
  I_N
  R_N
  
  ;
  
run;
 
 
proc sql;
	create table _plot as
		select ScenarioIndex, ModelType, date,S_N,E_N,I_N,R_N,count(*) 
		from store.model_final
		group by ScenarioIndex, ModelType, date,S_N,E_N,I_N,R_N
		order by ScenarioIndex, ModelType, date
	;
quit;


ods html5 file="/covid_analysis/modeling/AllScenarios.html" 
		gpath= "/covid_analysis/modeling/" 
		device=svg 
		options(svg_mode="inline");
		
 ods graphics / reset width=7in height=5in imagemap;	
	proc sgplot data=_plot;
		format s_n e_n i_n r_n comma12.;
		
		by scenarioindex modeltype;
		series x=date y=S_N / lineattrs=(color="orange") smoothconnect tip=(date s_n);
		series x=date y=E_N / lineattrs=(color="cyan") smoothconnect tip=(date e_n);
		series x=date y=I_N / lineattrs=(color="red") smoothconnect tip=(date i_n);
		series x=date y=R_N / lineattrs=(color="green") smoothconnect tip=(date r_n);
	run;
ods html5 close;
ods graphics / reset;
