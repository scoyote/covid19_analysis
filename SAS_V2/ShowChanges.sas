/********************************************************************/
/***** ShowChanges.sas - Run through all the graphs from load-plot*****/
/********************************************************************/

%let rc = %sysfunc(dlgcdir("/repositories/covid19_analysis/SAS_V2")); 
%include "MACROS.sas";
%let graphFormat=SVG;
options papersize=letter orientation=landscape nomprint nomlogic;
/* %include "LoadTimeseries.sas"; */
%let rc = %sysfunc(dlgcdir("/repositories/covid19_analysis/SAS_V2/graphs/graphs")); 
/********************************************************************/
/***** MACROS													*****/
/********************************************************************/
%macro plotIncreasing(lvl,direction=Increasing,topn=999);
	proc sql noprint;
		select compress(put(count(distinct &catvar.),3.)) into :maxplots from _regest where plotcat="&direction";
		select &catvar. into :loc1-:%cmpres(loc&maxplots) from _regest where plotcat="&direction" order by &catvar;
	quit;
	%do i=1 %to %sysfunc(min(&maxplots,&topn));
		%put NOTE: Calling plotstate macro: i=&i of %sysfunc(min(&maxplots,&topn)) state="&&loc&i";
 		%plotstate(state="&&loc&i",level=&lvl,numback=92); 
	%end;
%mend plotIncreasing; 



%macro runShowChanges(   level
						,catvar
						,analysisvar
						,analysisvar_label
						,region=
						,regwindow=7
						,lthresh=-0.5
						,uthresh=0.5
						,plotmin='01feb20'd
						,labelpos=topright);
	%if &level=cbsa %then %do;
		%let whcl=substr(cbsa_title,length(cbsa_title)-1,length(cbsa_title)) ="&region" and;
		%put NOTE: WHCL=&whcl;
	%end;
	%else %do;
		%let whcl=;
	%end;
	%let titleinclude=&region;
	data _null_;
		call symput("changesince",compress(intnx("days","&sysdate"d,%eval(&regwindow*(-1))))); run;data _null_;
		call symput('changesince_fmt',trim(left(put(&changesince,worddate19.)))); 
		call symput('refdate',put(&changesince,date5.)); 
		call symput('plotMonth',compress(intnx("months","&sysdate"d,-1))); run;data _null_;
		call symput('plotMonth_fmt',trim(left(put(&plotMonth,worddate19.)))); 
	run;
	%put [&changesince_fmt, &refdate, &plotmin,&plotMonth_Fmt)] ;
	
	data _plotdata _summarydata;
		set &level._trajectories(where=(&whcl dif7_confirmed>0));
		by &catvar. filedate;
		yval = ceil(&analysisvar);
		if last.&catvar. then do;
			plotlabel=&catvar.;
			output _summarydata;
		end;	
		gmonth=week(filedate);
		dday=day(filedate);
		if day(filedate) = 1 then boxprint=filedate; else boxprint=.;
		if &analysisvar<1 then &analysisvar=1;
		output _plotdata;
	run;
	
	ods graphics /reset=all height=16in width=20in;
	proc timeseries data=_plotdata
	                out=_series
	                outtrend=_trend
	                outseason=_season 
	                outdecomp=_decomp 
	                outsum=_summarydata
	                plots=none
	                ;
	   by &catvar.;
	   id filedate interval=day accumulate=average;
	   var &analysisvar;
	run;
	
	proc autoreg data=&level._trajectories(where=(&whcl filedate >=&changesince and &catvar. ~in("Alaska" "America Samoa" "Diamond Princess" "Grand Princess"))) 	
		outest=_regest(rename=(filedate=slope)) noprint ;
		by &catvar.;
		model &analysisvar=filedate;
	run;
	quit;
	/* proc sort data=_regest out=_dec; by slope; where slope <= -&thresh; run; */
	/* proc sort data=_regest out=_inc; by descending slope; where slope > -&thresh; run; */
	/* data _regest; set _inc _dec; run; */
	data _regest(drop=value linecolor id pattern) _colormap(keep=value id linecolor pattern); 
		set _regest;
		length linecolor $25;
		rownum+1;
		retain id value;
		if slope <= &Lthresh then do;
			plotcat="Decreasing";
			value=&catvar.;
			linecolor="cornflowerblue      ";
	/* 		transparency=0.5; */
			pattern='solid';
			id='setid';
			output _colormap;
		end;
		else if slope >= &Uthresh then do;
			plotcat="Increasing";
			value=&catvar.;
			linecolor='indianred';
	/* 		transparency=0.5; */
			pattern='solid';
			id='setid';
			output _colormap;
		end;
		else do;
			plotcat = "Steady"; 
			value=&catvar.;
			linecolor='teal';
			pattern='solid';
			id='setid';
			output _colormap;
		end;
		value=plotcat;
		output _regest;
	run;
	proc sql noprint;
		create table _regioncolor as	
			select &catvar as value, "regionid" as id, b.linecolor
			from _regest a
			left join 
			colormap(where=(linecolor~='Black')) b
			on a.rownum=b.value;
	quit;
	proc sql;
		create table _graph as 
		select a.&catvar., a.filedate, /*a.yval, c.tcc as*/ a.yval, b.plotcat as value
		from _plotdata a
		inner join _regest b
		on a.&catvar.=b.&catvar.
		inner join _decomp c
		on a.&catvar.=c.&catvar. and a.filedate=c.filedate
		order by &catvar., filedate
		;
	quit;
	data _graph; set _graph;
		by &catvar. filedate;
		if last.&catvar. then plotlabel=&catvar.;
		if yval=. then yval=0;
		format yval comma12.;
		label yval="&analysisvar_label";
	run;
	/********************** vvv overall vvv **************************/
	
	proc sql;
		create table _insets as 
			select value,count(distinct &catvar.) as freq 
				from _graph 
				group by value;
	
		create table _graph2 as	
		select a.value
				,filedate
				,cat(freq," ", propcase("&level")," or Regions") as freq
				,sum(yval) as yval
			from _graph a
			left join _insets b 
			on a.value=b.value
			group by a.value,freq,filedate
			order by a.value,freq,filedate
		;
	quit;
	data _graph2(drop=id linecolor) _color3(keep =id value linecolor); set _graph2;
		by value freq filedate;
		if last.value then plotlabel=freq;
		format yval comma12.;
		label yval="&analysisvar_label";
		if value='Steady' then linecolor='teal          ';
		else if value="Increasing" then linecolor='indianred     ';
		else if value="Decreasing" then linecolor='cornflowerblue';
		id='dirid';
		if first.value then output _color3;
		output _graph2;
	run;
	ods graphics /reset=all height=6in width=10.5in outputfmt=svg;
	
	
	
	
	ods html close;ods rtf close;ods pdf close;ods document close;
	options orientation=landscape papersize=tabloid  nomprint nomlogic;
	ods graphics on / reset width=16in height=10in imagemap outputfmt=&graphFormat imagefmt=&graphFormat; 
	/* Prep and print PDF title */ 
	%InsertPDFReportHeader(style=styles.htmlblue,fname=&level._&titleinclude.&regwindow._Focus,titlespec=&titleinclude. Directional);
	
	/* special report */
	%let overallplotdays=45;
	
	
	title "Overall - Since &changesince_fmt";
	ODS PROCLABEL "Increasing, Decreasing and Steady";
	proc sgplot data=_graph2(where=(yval >0 )) dattrmap=_color3;
		series x=filedate y=yval /  smoothconnect group=value datalabel=plotlabel lineattrs=(pattern=solid thickness=2) attrid=dirid;
		yaxis grid minorgrid offsetmin=0 offsetmax=0;
		xaxis min=&plotmin offsetmin=0 offsetmax=.1;
		refline &changesince /axis=x;
	run;
	quit;
	
	/********************** ^^^overall^^^ *************************/
	title "Increasing and Decreasing - Since &changesince_fmt";
	ODS PROCLABEL "All Regions";
	proc sgplot data=_graph(where=(yval >0 and value ~= "Steady" and filedate>&plotMonth)) dattrmap=_colormap noautolegend;
		series x=filedate y=yval /   smoothconnect group=&catvar. datalabel=plotlabel datalabelpos=&labelpos lineattrs=(pattern=solid) attrid=setid ;
		yaxis grid minorgrid offsetmin=0;
		xaxis min=&plotMonth offsetmin=0 offsetmax=.1;
		refline &changesince /axis=x;
	run;
	
	PROC SORT data=_graph; by descending &catvar. filedate; run;
	/* title "Steady - Since &changesince_fmt"; */
	/* ODS PROCLABEL "All - Steady"; */
	/* proc sgplot data=_graph(where=(yval >0 and value = "Steady" and filedate>&plotMonth)) noautolegend dattrmap=_regioncolor; */
	/* 	series x=filedate y=yval /  smoothconnect group=&catvar. datalabel=plotlabel datalabelpos=&labelpos lineattrs=(pattern=solid) attrid=regionid; */
	/* 	yaxis grid minorgrid offsetmin=0 ; */
	/* 	xaxis min=&plotMonth offsetmin=0 offsetmax=.1; */
	/* 	refline &changesince /axis=x; */
	/* run; */
	/* title "Increasing - Since &changesince_fmt"; */
	/* ODS PROCLABEL "All - Increasing"; */
	/* proc sgplot data=_graph(where=(yval >0 and value = "Increasing" and filedate>&plotMonth)) noautolegend  dattrmap=_regioncolor; */
	/* 	series x=filedate y=yval /  smoothconnect group=&catvar. datalabel=plotlabel datalabelpos=&labelpos lineattrs=(pattern=solid) attrid=regionid; */
	/* 	yaxis grid minorgrid offsetmin=0 ; */
	/* 	xaxis min=&plotMonth offsetmin=0 offsetmax=.1; */
	/* 	refline &changesince /axis=x; */
	/* run; */
	/* title "Decreasing - Since &changesince_fmt"; */
	/* ODS PROCLABEL "All - Decreasing"; */
	/* proc sgplot data=_graph(where=(yval >0 and value = "Decreasing"  and filedate>&plotMonth)) noautolegend  dattrmap=_regioncolor; */
	/* 	series x=filedate y=yval /  smoothconnect group=&catvar. datalabel=plotlabel datalabelpos= lineattrs=(pattern=solid) attrid=regionid; */
	/* 	yaxis grid minorgrid offsetmin=0 ; */
	/* 	xaxis min=&plotMonth offsetmin=0 offsetmax=.1; */
	/* 	refline &changesince /axis=x; */
	/* run; */
	/* quit; */
	
	%plotIncreasing(lvl=&level,direction=Increasing);
	
	proc sort data=_regest out=_report; by plotcat slope; run;
	data _report _a _b _c; set _report;
		by plotcat slope;
		retain pc ;
		if first.plotcat then pc=0;
		pc+1;
		keep plotcat &catvar. slope pc;
		output _report;
		     if plotcat="Increasing" then output _a;
		else 
		     if plotcat="Decreasing" then output _b;
		else
		     if plotcat="Steady" then output _c;
	run;
	proc datasets library=work nodetails nolist;
		modify _a;
			rename &catvar.=Increasing;
			rename slope = IncreasingSlope;
			rename plotcat = Increasingplotcat;
			rename pc = IncreasingPC;
		modify _b;
			rename &catvar.=Decreasing;
			rename slope = DecreasingSlope;
			rename plotcat = Decreasingplotcat;
			rename pc = DecreasingPC;
		modify _c;
			rename &catvar.=Steady;
			rename slope = SteadySlope;
			rename plotcat = Steadyplotcat;
			rename pc = SteadyPC;
	quit;
	proc sql;
		create table _report_final as	
		select * from _a left join _b on increasingpc=decreasingpc;
			;
	quit;
	
	ODS PROCLABEL "All Regions Slope Over Last &regwindow Days";
	proc print data=_report;
		var plotcat &catvar. slope; 
	run;
	ods pdf close;
%mend runShowChanges;	

%runShowChanges(state, province_state,ma7_new_confirmed,Confirmed Cases);

%runShowChanges(global, location,ma7_new_confirmed,Confirmed Cases);

%runShowChanges(cbsa,cbsa_title,ma7_new_confirmed,Confirmed Cases,region=GA);
%runShowChanges(cbsa,cbsa_title,ma7_new_confirmed,Confirmed Cases,region=NC);
%runShowChanges(cbsa,cbsa_title,ma7_new_confirmed,Confirmed Cases,region=SC);
%runShowChanges(cbsa,cbsa_title,ma7_new_confirmed,Confirmed Cases,region=FL);
%runShowChanges(cbsa,cbsa_title,ma7_new_confirmed,Confirmed Cases,region=AZ);
%runShowChanges(cbsa,cbsa_title,ma7_new_confirmed,Confirmed Cases,region=TX);
%runShowChanges(cbsa,cbsa_title,ma7_new_confirmed,Confirmed Cases,region=CA);
%runShowChanges(cbsa,cbsa_title,ma7_new_confirmed,Confirmed Cases,region=TN);
%runShowChanges(cbsa,cbsa_title,ma7_new_confirmed,Confirmed Cases,region=LA);
%runShowChanges(cbsa,cbsa_title,ma7_new_confirmed,Confirmed Cases,region=OK);
%runShowChanges(cbsa,cbsa_title,ma7_new_confirmed,Confirmed Cases,region=NV);
%runShowChanges(cbsa,cbsa_title,ma7_new_confirmed,Confirmed Cases,region=OH);



