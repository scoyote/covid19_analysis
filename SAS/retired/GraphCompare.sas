proc sql;
select distinct location into :subs separated by '","' from jhu_icu_timeseries 
where confirmed between 6000 and 7000 and scan(location,2,'-')='US';
quit;

%put ("&subs");
data &region_name._summary;
	set JHU_icu_TimeSeries(where=(location in ("&subs")));
	/* add adjustment here */
	%AddAdjustment(&adjust_type,&adjust_date,&adjust_confirmed,&adjust_deaths);
	dif_Confirmed = confirmed-lag(confirmed);
	dif_deaths = deaths-lag(deaths);
	label confirmed="Number of Confirmed Infections";
	label deaths = "Number of Deaths";
	label dateplot = "Date of Report";
	label dif_confirmed = "New Cases";
	label dif_deaths="New Deaths";
	format confirmed comma11. deaths comma11.;
	dateplot = substr(filedate,5,2)||"-"||substr(filedate,7,2);
run;

proc sort data=&region_name._summary; by location filedate; run;

options orientation=landscape papersize=(8in 5in) ;
ods graphics on / reset width=8in height=5in  imagemap outputfmt=svg;
ods html close;ods rtf close;ods pdf close;ods document close; 
ods html5 file="&outputpath./States/Compare.html" gpath= "&outputpath/states/" device=svg options(svg_mode="inline");
	
	
	title "Overlay";
	footnote 'Data Source: Johns Hopkins University - https://github.com/CSSEGISandData/COVID-19';
	

	proc sgplot data=&region_name._summary nocycleattrs;
		scatter y=confirmed x=dateplot  / group=location ;
		series y=confirmed x=dateplot  	/ group=location ;
/* 		scatter  y=deaths x=dateplot 	/ group=location y2axis ; */
/* 		series y=deaths x=dateplot 		/ group=location y2axis ; */
		yaxis ; 
/* 		y2axis ; */
		xaxis  valueattrs=(size=5);
		keylegend / location=outside;
	run;
	
	
ods html5 close;
ods graphics / reset;
	
	
	
	
	
	
	