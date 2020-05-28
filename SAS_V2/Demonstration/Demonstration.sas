/*********************************************************************************/
/***** Analysis and Visualization Section									 *****/
/*********************************************************************************/

%let analysisStartDate	='20may2020'd;
%let plotStartDate		='01apr2020'd;

	ods graphics /reset=all height=6in width=10in;
	proc timeseries data=&regionName._overall(where=(reportdate >=&plotStartDate))
					out=_series
/* 	                outtrend=_trend outseason=_season outdecomp=_decomp outsum=_summarydata */
	                plots=all
	                ;
	   id reportdate interval=day accumulate= max setmissing=0;
	   var DailyCases;
	run;
	
	proc arima data=&regionName._overall(where=(reportdate >=&plotStartDate));
		identify var=DailyCases(0,7) scan esacf ; run;
		estimate p=1 q=0  plot; run;
	quit;
	
	proc autoreg data=&regionName._overall(where=(reportdate >= &analysisStartDate))
		outest=_regest(rename=(reportdate=slope) ) ;
		model DailyCases=reportDate;
	run;
	quit;


	
/* 	***** Texas Fips ***** */
	proc sort data=&regionName._fips;
		by fips combined_key  reportdate;
	run;
	
	proc autoreg data=&regionName._fips(where=(reportdate >= &analysisStartDate))
		outest=_regest(rename=(reportdate=slope) ) noprint ;
		by fips combined_key;
		model DailyCases=reportdate;
	run;
	quit;
	
	
	data &regionName._fips; set &regionName._fips;
		by fips combined_key;
		if last.fips then plotlabel=combined_key;
	run;
	data _regest; set _regest;
		if slope < -0.1 then value="Decreasing";
		else if slope >= 0.1 then value="Increasing";
		else value="Steady";
	run;
	
	proc sql;
		create table _graph as
			select 
				 b.value
				,a.reportdate
				,sum(a.dailyCases) as DailyCases
			from &regionName._fips a 
			left join _regest b
			on a.fips=b.fips
			group by value, reportdate
			order by value, reportdate;
	quit;
	
	data _graph2(drop=id linecolor) _color3(keep =id value linecolor); 
		set _graph;
		by value reportdate;
		if last.value then plotlabel=value;
		format dailyCases comma12.;
		if value='Steady' then linecolor='teal          ';
		else if value="Increasing" then linecolor='indianred     ';
		else if value="Decreasing" then linecolor='cornflowerblue';
		id='dirid';
		if first.value then output _color3;
		output _graph2;
	run;
ODS PROCLABEL "All - Decreasing";
proc sgplot data=_graph2(where=(reportdate>&plotStartDate)) noautolegend dattrmap=_color3 ;
	series x=reportdate y=dailycases /  smoothconnect group=value datalabel=plotlabel datalabelpos=topleft lineattrs=(pattern=solid) attrid=dirid ;
	yaxis grid minorgrid offsetmin=0 ;
	xaxis min=&plotStartDate offsetmin=0 offsetmax=.1;
	refline &analysisStartDate /axis=x;
run;
quit;



	proc datasets library=work;
		delete
			_series
			_texas_exp
			_texas_temp
		;
	quit;
	