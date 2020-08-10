%let stateplot=SC;
%let analysisvar=MA7_new_confirmed;
%let tipvars=dif1_confirmed dif1_deaths;
%let startdate='01mar20'd;
/*
proc sql;
select distinct cbsa_title from cbsa_trajectories where substr(cbsa_title,length(cbsa_title)-1, length(cbsa_title))="&stateplot";
quit;
*/
%let seed 		= 1;
%let blocklevel = 1;

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


data _graph
	 _cc(keep=cbsa_title cbsacolormatch) ; 
	; 
	set CBSA_TRAJECTORIES (where=(filedate >= &startdate and substr(cbsa_title,length(cbsa_title)-1, length(cbsa_title))="&stateplot"));
	by cbsa_title filedate;
	if last.cbsa_title then do;
		tips=cbsa_title;
	end;
	value=_n_;
	output _graph;
	if _n_=1 then cbsacolormatch=1; 
	if last.cbsa_title then do;
		cbsacolormatch+1;
		output _cc;
	end;
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


ods html5  path="graphs" body="CBSADaily_&StatePlot..htm" (url=none) options(bitmap_mode="inline");
ods graphics / reset width=12in height=8in imagemap=on tipmax=100000  imagefmt=svg;

title 	  "SARS-COV-2: CBSA Contribution per Reporting Date for &Stateplot as of &wordDte";
title2 	  h=1 "Updated &wordDte";
footnote  j=c h=1 "Beware of drawing conclusions from this data beyond the purpose for which it was generated.";
footnote2 j=c h=.95 "Data Source: Johns Hopkins University - https://github.com/CSSEGISandData/COVID-19 Data Updated: &sysdate";
footnote3 j=r h=0.5  "Samuel T. Croker - &sysdate9";

proc sgplot data=_graph des="CBSA Daily Contribution for &stateplot" noautolegend dattrmap=_cbsacolor ;
	vbar Filedate / nooutline
		response=&ANALYSISVAR    
		group=CBSA_Title 
		groupdisplay=stack 
		fillattrs=(transparency=0.5)
		tip=(CBSA_Title FileDate &analysisvar &tipvars)
		attrid=c_ramp
		;
	xaxis fitpolicy=rotatethin;
	yaxis ;
run;


proc sort data=_graph out=_maxgroup; 
	by descending &analysisvar; 
	where filedate=intnx('day',"&sysdate"d,-1); 
run;
data _maxgroup; set _maxgroup;
	ordr=_n_;
run;
proc sql noprint;;
	select cbsa_title into :blocks separated by '","' from _maxgroup where ordr <=&blocklevel;
	select cbsa_title into :tblocks separated by '; ' from _maxgroup where ordr <=&blocklevel;
quit;
%put blocks =("&blocks");
%put tblocks=("&tblocks");

title 	  "SARS-COV-2: CBSA Contribution per Reporting Date for &Stateplot as of &wordDte";
title2 	  h=1 "Updated &wordDte";
title3 	  h=0.75 "Major CBSAs Removed";
title4 	  h=0.75 "&tblocks";
footnote  j=c h=1 "Beware of drawing conclusions from this data beyond the purpose for which it was generated.";
footnote2 j=c h=.95 "Data Source: Johns Hopkins University - https://github.com/CSSEGISandData/COVID-19 Data Updated: &sysdate";
footnote3 j=r h=0.5  "Samuel T. Croker - &sysdate9";

proc sgplot data=_graph(where=(cbsa_title not in ("&blocks"))) des="CBSA Daily Contribution for &stateplot Removed" noautolegend dattrmap=_cbsacolor ;
	vbar Filedate / nooutline
		response=&ANALYSISVAR    
		group=CBSA_Title 
		groupdisplay=stack 
		fillattrs=(transparency=0.5)
		tip=(CBSA_Title FileDate &analysisvar &tipvars)
		attrid=c_ramp
		;

	xaxis fitpolicy=rotatethin;
	yaxis ;
run;


ods html5 close;
ods graphics / reset;

title; footnote;
