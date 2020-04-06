*********************************************************************
***** GraphSingular.sas - 3rd Generation program for plotting 	*****
*****						small regions.						*****
***** pulls and prepares csv data from covid19 and analyzes 	*****
***** data														*****
*********************************************************************;

/***************************************/
/* Passed in from runner, or set here  */
/* %let pvs=Georgia;%let suffix='-US'; */
/***************************************/
data _null_; 
	call symput("region_name",compress("&pvs")); 
	call symput("location",cats("&prefix.&pvs.&suffix"));
run;

%put NOTE: Running &region_name [&prefix, &pvs, &suffix] for "&location";

/* this is a stub that will add data from the runner program*/
%AddData(&add_typer,&location,&add_date,&add_confirmed,&add_deaths);

proc sql;create table temp_summary as
			select 
				 location
				,filedate
				,sum(confirmed) as confirmed
				,sum(deaths) as deaths
				,sum(recovered) as recovered
				,max(population_estimate) as population_estimate label="2010 County Poputlation Estimate"
				,max(county_hospitals) as total_county_hospitals label="Total County Hospitals"
				,max(county_icu_beds) as total_county_icu_beds label="Total ICU Beds"
				,max(emp_fatality_rate) as emp_fatality_rate format=percent7.5 label="Fatality Rate"
				,max(confirmed_percapita) as confirmed_percapita format=percent7.5 label="Infections Per Capita"
				,max(deaths_percapita) as deaths_percapita  format=percent7.5 label="Deaths Per Capita"
			from JHU_CORE_LOC_CENSUS_ICU_SUMMARY
			where location="&location"
			group by 
				location
				,filedate
			order by  
				location
				,filedate
			;
quit;
data &region_name._summary;
	set temp_summary;
	/* add adjustment here */
	%AddAdjustment(&adjust_type,&adjust_date,&adjust_confirmed,&adjust_deaths);
	dif_Confirmed = confirmed-lag(confirmed);
	dif_deaths = deaths-lag(deaths);
	label confirmed="Number of Confirmed Infections";
	label deaths = "Number of Deaths";
	label filedate = "Date of Report";
	label dif_confirmed = "New Cases";
	label dif_deaths="New Deaths";
	format confirmed comma11. deaths comma11.;
run;

proc sql;
	create table plotstack as
	(select filedate,"Confirmed" as lab, confirmed as stack from &region_name._summary)
	union
	(select filedate,"Deaths" as lab, deaths as stack from &region_name._summary)
	order by lab, filedate;
quit;

data attrmap;
	retain id "myid";
	informat value $10.;
	input value $  fillcolor $ linecolor $ ;
datalines; 
Confirmed CX6599C9 black
Deaths CXEDAF64 black
;
run;

proc sort data=&region_name._summary; by filedate; run;

options orientation=landscape papersize=(8in 5in) ;
ods graphics on / reset width=8in height=5in  imagemap outputfmt=svg;
ods html close;ods rtf close;ods pdf close;ods document close; 
ods html5 file="&outputpath./States/&pvs..html" gpath= "&outputpath/states/" device=svg options(svg_mode="inline");
	title "&PVS COVID-19 Situation Report";
	title2 "New Cases and New Deaths";
	%SetNote;
	footnote 'Data Source: Johns Hopkins University - https://github.com/CSSEGISandData/COVID-19';
	
	
	proc sgplot data=&region_name._summary nocycleattrs ;
		vbar filedate / response=dif_confirmed stat=sum ;*lineattrs=(color='red') ;
		vline filedate / response=dif_deaths stat=sum y2axis;
		yaxis ; 
		y2axis ;
		xaxis  valueattrs=(size=5);
		keylegend / location=outside;
	run;	
	
	title "&PVS COVID-19 Situation Report";
	title2 "Prevalence and Deaths";
	%SetNote;
	footnote 'Data Source: Johns Hopkins University - https://github.com/CSSEGISandData/COVID-19';
	

	proc sgplot data=plotstack nocycleattrs dattrmap=attrmap;
		label filedate="File Date"
			  stack="Value"
			  lab="Measure";
		format stack comma11.;
		vbar filedate / response=stack stat=sum group=lab transparency=.15 attrid=myid
		tip=(filedate lab stack) 
		tiplabel=("Date" "Type" "Value") 
		tipformat= ($10. $20. comma10.);
		yaxis ; 
		xaxis  valueattrs=(size=6) ;
		keylegend / location=outside;
	run;
	
	
	proc sgplot data=&region_name._summary nocycleattrs;
		scatter y=confirmed x=filedate  /
			FILLEDOUTLINEDMARKERS 
			MARKERFILLATTRS=(color='CX6599C9') 
			MARKEROUTLINEATTRS=(color='CX6599C9') 
			markerattrs=(symbol=CircleFilled color='CX6599C9');
		series y=confirmed x=filedate  	/ 
			lineattrs=(color='blue') 
			legendlabel=" ";
		scatter  y=deaths x=filedate 	/  
			FILLEDOUTLINEDMARKERS 
			MARKERFILLATTRS=(color='CXEDAF64') 
			MARKEROUTLINEATTRS=(color='CXEDAF64')  
			markerattrs=(symbol=CircleFilled color='cxedaf64' ) 
			y2axis ;
		series y=deaths x=filedate 		/ 
			y2axis lineattrs=(color='red') 
			legendlabel=" ";
		yaxis ; 
		y2axis ;
		xaxis  valueattrs=(size=5);
		keylegend / location=outside;
	run;
ods html5 close;
ods graphics / reset;

proc delete data=&region_name._summary plotstack attrmap temp_summary; run;

