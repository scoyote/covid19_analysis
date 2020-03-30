*****************************************************************
***** Georgia.sas
***** pulls and prepares csv data from covid19 and analyzes GA 
***** data
*****************************************************************
;
/* keep the region name such that datasets match actual data name */
*****************************;
%let pvs=Georgia;
*****************************;
data _null_; call symput("region_name",compress("&pvs")); run;


/* *****************************; */
/* proc sql; select distinct location, filedate from jhu_final where upcase(location) like "LOU%"; */
/* quit; */

data &region_name;
	set  WORK.JHU_current;
	where location = "&pvs-US";
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
data &region_name._summary;
	set &region_name._summary;
	label confirmed="Number of Confirmed Infections";
	label deaths = "Number of Deaths";
	label dateplot = "Date of Report";
	dateplot = substr(filedate,5,2)||"-"||substr(filedate,7,2);
Run;
/* use this sql to add values that are not in the 
	daily extract, but are available */
/* proc sql; */
/* 	insert into &region_name._summary  */
/* 		(_type_,_freq_,dateplot, confirmed, deaths)  */
/* 		values (1,160,"03-28",2366,69); */
/* quit; */
/* Compute response min and max values (include 0 in computations) */
data _null_;
	retain respmin 0 respmax 0;
	retain respmin1 0 respmax1 0 respmin2 0 respmax2 0;
	set &region_name._summary end=last;
	respmin1=min(respmin1, confirmed);
	respmin2=min(respmin2, deaths);
	respmax1=max(respmax1, confirmed);
	respmax2=max(respmax2, deaths);
	if last then
		do;
			call symputx ("respmin1", respmin1);
			call symputx ("respmax1", respmax1);
			call symputx ("respmin2", respmin2);
			call symputx ("respmax2", respmax2);
			call symputx ("respmin", min(respmin1, respmin2));
			call symputx ("respmax", max(respmax1, respmax2));
		end;
run;

/* Define a macro for offset */
%macro offset ();
	%if %sysevalf(&respmin eq 0) %then
		%do;
			offsetmin=0 %end;

	%if %sysevalf(&respmax eq 0) %then
		%do;
			offsetmax=0 %end;
%mend offset;



options orientation=landscape papersize=(8in 8in) ;
ods graphics / reset width=7in height=4.5in imagemap;
ods pdf file="&outputpath./Georgia.pdf";
	title "&PVS COVID-19 Situation Report";
	title2 "Prevalence and Deaths";
	footnote "Source Johns Hopkins University CSSE: https://dph.georgia.gov/covid-19-daily-status-report";
	proc sgplot data=&region_name._summary nocycleattrs;
		vbar dateplot / response=confirmed stat=sum;
		vline dateplot / response=deaths stat=sum y2axis;
		yaxis grid min=&respmin1 max=&respmax1 %offset(); 
		y2axis min=&respmin2 max=&respmax2 %offset();
		keylegend / location=outside;
	run;
ods pdf close;
ods graphics / reset;




