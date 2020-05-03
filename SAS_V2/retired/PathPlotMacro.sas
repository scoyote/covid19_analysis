
%macro plotPaths(level,procvar,title,maxplots=10,style=styles.htmlblue);
	proc sort data=&level._trajectories; by &procvar filedate; run;
	data _trajectories;
		set &level._trajectories;
		label days_since_death1 = "Days Since First Death";
		by &procvar filedate;
		array ddflag[2]  _temporary_;
		retain ddflag;
		if first.&procvar then do;
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
	proc sort data=_trajectories; by &procvar descending filedate; run;
	data _trajectories ; set _trajectories;
		by &procvar descending filedate;
		array dd[1] _temporary_;
		if first.&PROCVAR then dd[1]=0;
		if ma7_new_deaths > 0.5 and dd[1]=0 then do;
			lastdeath = 1;
			dd[1] = 1;
		end;
		else lastdeath=0;
	run;
	
		proc sort data=_trajectories(where=(plotseq=1)) out=_t ;
			by descending ma7_new_confirmed;
		run;
		data _t; set _t;
			by descending  ma7_new_confirmed;
			plotset=_n_;
		run;
		proc sort data=_t ;by descending deaths;run;
		data _t; set _t;
			by descending  deaths;
			plotdeathset=_n_;
		run;
		proc sql noprint;
			create table Death_trajectories as	
				select a.*,b.plotset,b.plotdeathset, 
				case when a.plotseq=1 or a.lastdeath=1 then a.&procvar else "" end as plot_label
				from _trajectories a
				inner join _t b
				on a.&procvar=b.&procvar
				order by &procvar, filedate;
		quit;
	%if &maxplots=0 %then %do;
		proc sql noprint;
			select ceil((max(days_since_death1)+.01)/10)*10 into :deathmax from death_trajectories;
		quit; 
		%put deathmax=&deathmax ;
		
		title;footnote;
			title 	  h=1 "All &title SARS-CoV-2 Trajectories";
			footnote  h=1"Data Source: Johns Hopkins University - https://github.com/CSSEGISandData/SARS-CoV-2  Data Updated: &sysdate";
			footnote3 h=0.9 justify=right "Samuel T. Croker - &sysdate9";
			ods proclabel "Top &maxplots &title Trajectories"; 
			ods pdf file = "/covid_analysis/SAS_V2/graphs/&title._all_path.pdf" style=&style;
			proc sgplot 
				data=death_trajectories(where=(ma7_new_deaths>0 ))
				noautolegend nocycleattrs noborder
				des="&title Paths Since Death One";
				series x=days_since_death1 y=ma7_new_deaths  / group=&procvar 
					datalabel=plot_label datalabelpos=top
					datalabelattrs=(size=10  ) 
					lineattrs =(thickness=2 pattern=solid )
					transparency=0.25;
				xaxis minor /*grid minorgrid*/display=(noline)   max=%eval(&deathmax) offsetmax=0 offsetmin=0  labelattrs=(size=10) valueattrs=(size=12) values=(0 to &deathmax by 10 ) ;
				yaxis minor /*grid minorgrid*/display=(noline)  type=log labelattrs=(size=15) valueattrs=(size=12) LOGSTYLE=LOGEXPAND ;
			run;
			ods pdf close;
	%end;
	%else %if &maxplots < 0 %then %do;
		%let maxplots=%eval(-1*&maxplots);
		proc sql noprint;
			select ceil((max(days_since_death1)+.01)/20)*20 into :deathmax from death_trajectories(where=(ma7_new_deaths>0 and plotdeathset<=abs(&maxplots)));
		quit; 
		%put deathmax=&deathmax ;
			title 	  h=1 "Top &maxplots &title Deaths SARS-CoV-2 Trajectories";
			footnote  h=1 "Data Source: Johns Hopkins University - https://github.com/CSSEGISandData/SARS-CoV-2  Data Updated: &sysdate";
			footnote3 h=0.9 justify=right "Samuel T. Croker - &sysdate9";
			ods proclabel "Top &maxplots &title Trajectories"; 
		ods pdf file = "/covid_analysis/SAS_V2/graphs/&title._path.pdf" style=&style;
			proc sgplot 
				data=death_trajectories(where=(ma7_new_deaths>0 and plotdeathset<=abs(&maxplots)))
				noautolegend nocycleattrs noborder
				des="&title Deaths Paths Since Death One";
				series x=days_since_death1 y=ma7_New_deaths  / group=&procvar 
					datalabel=plot_label datalabelpos=top
					datalabelattrs=(size=10 ) 
					lineattrs =(thickness=2 pattern=solid ) 
					transparency=0.25;
				xaxis minor  /*grid minorgrid*/display=(noline)   max=%eval(&deathmax) offsetmax=0 offsetmin=0        labelattrs=(size=10) valueattrs=(size=12) values=(0 to &deathmax by 20 ) ;
				yaxis minor /*grid minorgrid*/display=(noline)  type=log labelattrs=(size=15) valueattrs=(size=12) LOGSTYLE=LOGEXPAND ;
			run;
		ods pdf close;

	%end;
	%else %do;
		proc sql noprint;
			select ceil((max(days_since_death1)+.01)/10)*10 into :deathmax from death_trajectories(where=(plotset<=abs(&maxplots)));
		quit; 
		%put deathmax=&deathmax ;
			title 	  h=1 "&title - Top &maxplots SARS-CoV-2 Trajectories";
			footnote  h=1 "Data Source: Johns Hopkins University - https://github.com/CSSEGISandData/SARS-CoV-2  Data Updated: &sysdate";
			footnote3 h=0.9 justify=right "Samuel T. Croker - &sysdate9";
			ods proclabel "Top &maxplots &title Trajectories"; 
		ods pdf file = "/covid_analysis/SAS_V2/graphs/&title._path.pdf" style=&style;
			proc sgplot noborder
				data=death_trajectories(where=(ma7_new_deaths>0 and plotset<=abs(&maxplots)))
				noautolegend nocycleattrs
				des="&title Paths Since Death One";
				series x=days_since_death1 y=ma7_new_deaths  / group=&procvar 
					datalabel=plot_label datalabelpos=top
					datalabelattrs=(size=10 ) 
					lineattrs =(thickness=2 pattern=solid )
					transparency=0.25;
				xaxis minor /*grid minorgrid*/display=(noline)  max=%eval(&deathmax) offsetmax=0 offsetmin=0        labelattrs=(size=15) valueattrs=(size=12) values=(0 to &deathmax by 10 ) ;
				yaxis minor /*grid minorgrid*/display=(noline) type=log labelattrs=(size=15) valueattrs=(size=12) LOGSTYLE=LOGEXPAND ;
			run;
		ods pdf close;
	%end;
%mend PlotPaths;

options orientation=landscape papersize=tabloid ;
ods graphics on / reset=all height=10in width=16in ;



proc template;
   define style stcstyle;
   parent=styles.htmlblue;
      class graphwalls / 
            frameborder=off;
   end;
run;

%plotpaths(state,province_state,title=US States,maxplots=0);
%plotpaths(state,province_state,title=US States,maxplots=15);
%plotpaths(global,location,title=Nations,maxplots=-20,style=stcstyle);
%plotpaths(cbsa,cbsa_title,title=US CBSAs,maxplots=10);