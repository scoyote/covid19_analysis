%let numback=10;
%let maxplots=10;
proc sort data=state_trajectories; by province_state filedate; run;
data _trajectories;
	set state_trajectories;
	label days_since_death1 = "Days Since First Death";
	by province_state filedate;
	array ddflag[1]  _temporary_;
	retain ddflag;
	if first.province_state then do;
		days_since_death1 = 0;
		ddflag[1]=0;
	end;
	if ddflag[1] = 0 then do;
		if dif1_deaths > 0.5 then ddflag[1] = 1;
	end;
	else do;
		 days_since_death1 + 1;
	end;
	if ddflag[1] then output;
run;

	proc sort data=_trajectories(where=(plotseq=1)) out=_t ;
		by descending ma7_new_confirmed;
	run;
	data _t; set _t;
		by descending  ma7_new_confirmed;
		plotset=_n_;
	run;
	
	proc sql noprint;
		create table Death_trajectories as	
			select a.*,b.plotset, 
			case when a.plotseq=1 then a.province_state else "" end as plot_label
			from _trajectories a
			inner join _t b
			on a.province_state=b.province_state
			order by province_state, filedate;
	quit;
	proc sql noprint;
		select ceil((max(days_since_death1)+.01)/5)*5 into :deathmax from death_trajectories;
	quit; 
	%put deathmax=&deathmax ;
	
	ods graphics on / reset=all height=7in width=16in;
	title;footnote;
		title 	  h=1 "All US States SARS-CoV-2 Trajectories";
		footnote  h=1"Data Source: Johns Hopkins University - https://github.com/CSSEGISandData/SARS-CoV-2  Data Updated: &sysdate";
		footnote3 h=0.9 justify=right "Samuel T. Croker - &sysdate9";
		ods proclabel "Top &maxplots US States Trajectories"; 
		proc sgplot 
			data=death_trajectories
			noautolegend nocycleattrs
			des="State Paths Since Death One";
			series x=days_since_death1 y=Confirmed  / group=province_state 
				datalabel=plot_label datalabelpos=topleft
				datalabelattrs=(size=10 ) 
				lineattrs =(thickness=3 pattern=solid )
				transparency=0.25;
			xaxis grid minor minorgrid  max=%eval(&deathmax+5) offsetmax=0 offsetmin=0        labelattrs=(size=15) valueattrs=(size=12) values=(0 to &deathmax by 5 ) ;
			yaxis grid minor minorgrid type=log labelattrs=(size=15) valueattrs=(size=12) LOGSTYLE=LOGEXPAND ;
		run;
	proc sql noprint;
		select ceil((max(days_since_death1)+.01)/5)*5 into :deathmax from death_trajectories(where=(plotset<=&maxplots));
	quit; 
	%put deathmax=&deathmax ;
		title 	  h=1 "US States - Top &maxplots SARS-CoV-2 Trajectories";
		footnote  h=1"Data Source: Johns Hopkins University - https://github.com/CSSEGISandData/SARS-CoV-2  Data Updated: &sysdate";
		footnote3 h=0.9 justify=right "Samuel T. Croker - &sysdate9";
		ods proclabel "Top &maxplots US States Trajectories"; 
		proc sgplot 
			data=death_trajectories(where=(plotset<=&maxplots))
			noautolegend nocycleattrs
			des="State Paths Since Death One";
			series x=days_since_death1 y=Confirmed  / group=province_state 
				datalabel=plot_label datalabelpos=topleft
				datalabelattrs=(size=10 ) 
				lineattrs =(thickness=3 pattern=solid )
				transparency=0.25;
			xaxis grid minor minorgrid  max=%eval(&deathmax+5) offsetmax=0 offsetmin=0        labelattrs=(size=15) valueattrs=(size=12) values=(0 to &deathmax by 5 ) ;
			yaxis grid minor minorgrid type=log labelattrs=(size=15) valueattrs=(size=12) LOGSTYLE=LOGEXPAND ;
		run;
		
		
		

		