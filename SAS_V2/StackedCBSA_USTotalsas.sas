%let stateplot=GA;
%let analysisvar=dif7_confirmed;
%let startdate='01mar20'd;

%let seed = 5;

options nomprint nomlogic;
data _null_ ;call symput("wordDte",trim(left(put("&sysdate9"d, worddatx32.)))); run;
%put worddte[&wordDte];

data _colors;
/* Good set ('CC','E5','99','00') */
	array cols{4} $ _temporary_ ('CC','E5','99','00');

	retain id 'c_ramp';
	do i=1 to dim(cols);
		do j=1 to dim(cols);
			do k=1 to dim(cols);
				if i=j and j=k and i=j then continue;
				runi=ranuni(&seed);
				color=compress('CX'||cols[i]||cols[j]||cols[k]);
				drop i j k;
				fillcolor=color;
				linecolor=color;
				output;
			end;
		end;
	end;
run;

proc sort data=_colors; by runi; run;
data _colors; set _colors;
	value = _n_;
	drop runi;
run;
%let maxcutoff=50;
proc sql noprint; 
	create table cbsalevel as
	select cbsa_title,max(confirmed) as maxcase, max(deaths) as maxdeaths
	from cbsa_trajectories 
	group by cbsa_title
	order by maxcase desc; 
quit;
data _null_; set cbsalevel;
	if _n_ = &maxcutoff+1 then call symput("cutoff",maxcase);
run;
proc sql noprint;
	select count(*) into :numk from cbsalevel where maxcase>&cutoff;
	select distinct cbsa_title into :cbsa1-:cbsa%cmpres(&numk) from cbsalevel where maxcase>=&cutoff;
	select distinct cbsa_title into :cbsas separated by '","' from cbsalevel where maxcase>=&cutoff;
quit;

data _graph(keep=filedate cbsa_title &analysisvar) 
	 _cc(keep=cbsa_title cbsacolormatch) ; 
	set cbsa_trajectories;
	by cbsa_title filedate;
	if _n_=1 then cbsacolormatch=1; 
	where cbsa_title in ("&cbsas");
	if filedate >= &startdate;
	if &analysisvar < 1 then &analysisvar=1;
	if last.cbsa_title then do;
		cbsacolormatch+1;
		output _cc;
	end;
	output _graph;
run;


proc sql noprint;
	create table _cbsacolor as	
		select cbsa_title, b.* 
		from _cc a 
			inner join _colors b 
			on a.cbsacolormatch=b.value
			;
quit;
		
data _cbsacolor; set _cbsacolor(drop=value);
	value=cbsa_title;
run;


ods graphics / reset=all width=12in height=8in imagemap=on tipmax=100000  imagefmt=svg;
ods html5  path="graphs" body="CBSADaily_Top&maxcutoff..htm" (url=none) options(bitmap_mode="inline");

title 	  "SARS-COV-2: CBSA Contribution per Reporting Date for Top &maxcutoff by Cases";
title2 	  h=1 "Updated &wordDte";
footnote  j=c h=1 "Beware of drawing conclusions from this data beyond the purpose for which it was generated.";
footnote2 j=c h=.95 "Data Source: Johns Hopkins University - https://github.com/CSSEGISandData/COVID-19 Data Updated: &sysdate";
footnote3 j=r h=0.5  "Samuel T. Croker - &sysdate9";

proc sgplot data=_graph des="CBSA Daily Contribution for top &maxcutoff CBSAs" noautolegend dattrmap=_cbsacolor ;
	vbar Filedate / nooutline
		response=&ANALYSISVAR    
		group=CBSA_Title 
		groupdisplay=stack 
		fillattrs=(transparency=.5)
		tip=(CBSA_Title FileDate &analysisvar) 
		attrid=c_ramp
		;

	xaxis fitpolicy=rotatethin;
	yaxis ;*type=log offsetmin=1 min=10 values=(10 100 1000 to 10000 by 1000) ;
run;

ods html5 close;
ods graphics / reset;


title;footnote;

