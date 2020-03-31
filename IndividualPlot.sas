*****************************************************************
***** IndividualPlot.sas
***** pulls and prepares csv data from covid19 and analyzes 
***** data
*****************************************************************;
%global adjust_note	adjust_date adjust_confirmed adjust_deaths;
*****************************;
data _null_; call symput("region_name",compress("&pvs")); run;

/* ******************************/
/* proc sql; select distinct location, filedate from jhu_final where upcase(location) like "LOU%"; */
/* quit; */

data &region_name;
	set  WORK.JHU_current;
	where location = "&pvs.&suffix";
run;

/* Calculate the daily sums over region - this really applies once
 	you are into the datasets that are disaggregated to county or provinces
*/
proc sort data=&region_name; by filedate; run;
proc means data=&region_name noprint;
	class filedate / order=data;
	var confirmed deaths;
	output out=&region_name._summary
		(where=(_type_ > 0)) 
		sum(confirmed deaths)=confirmed deaths;
run;

/* this is a stub that will add data from the runner program*/
%AddData(&add_typer,&add_date,&add_confirmed,&add_deaths);

data &region_name._summary;
	set &region_name._summary;
	/* add adjustment here */
	%AddAdjustment(&adjust_type,&adjust_date,&adjust_confirmed,&adjust_deaths);
	dif_Confirmed = confirmed-lag(confirmed);
	dif_deaths = deaths-lag(deaths);
	label confirmed="Number of Confirmed Infections";
	label deaths = "Number of Deaths";
	label dateplot = "Date of Report";
	label dif_confirmed = "New Cases";
	label dif_deaths="New Deaths";
	dateplot = substr(filedate,5,2)||"-"||substr(filedate,7,2);
run;

options orientation=landscape papersize=(8in 8in) ;
ods graphics on / reset width=7in height=6.5in  imagemap outputfmt=svg;
ods html close;ods rtf close;ods pdf close;ods document close; 
ods html5 file="&outputpath./States/&pvs..html" gpath= "&outputpath/states/" device=svg options(svg_mode="inline");
	title "&PVS COVID-19 Situation Report";
	title2 "New Cases and New Deaths";
	%SetNote;
	footnote 'Data Source: Johns Hopkins University - https://github.com/CSSEGISandData/COVID-19';
	
	
	proc sgplot data=&region_name._summary nocycleattrs;
		vbar dateplot / response=dif_confirmed stat=sum ;*lineattrs=(color='red') ;
		vline dateplot / response=dif_deaths stat=sum y2axis;
		yaxis grid; 
		y2axis ;
		keylegend / location=outside;
	run;	title "&PVS COVID-19 Situation Report";
	
	
	title2 "Prevalence and Deaths";
	%SetNote;
	footnote 'Data Source: Johns Hopkins University - https://github.com/CSSEGISandData/COVID-19';
	
	
	proc sgplot data=&region_name._summary nocycleattrs;
		vbar dateplot / response=confirmed stat=sum ;*lineattrs=(color='red') ;
		vline dateplot / response=deaths stat=sum y2axis;
		yaxis grid ; 
		y2axis grid ;
		keylegend / location=outside;
	run;
ods html5 close;
ods graphics / reset;



