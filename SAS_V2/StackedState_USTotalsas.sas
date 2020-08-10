
%let analysisvar=ma7_new_confirmed;
%let tipvars = dif1_confirmed dif1_deaths ;
%let startdate='01mar20'd;
%let maxcutoff=50;
%let seed = 4;

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
data _colors; set _colors end=eof;
	value = _n_;
	drop runi;
	if eof then do;
		value=_n_+1;
		color='YWH';
		fillcolor=color;
		linecolor=color;
		call symput('othercolor',value);
	end;
run;
proc sql noprint; 
	create table statelevel as
	select province_state,max(confirmed) as maxcase, max(deaths) as maxdeaths
	from state_trajectories 
	group by province_state
	order by maxcase desc; 
quit;
data _null_; set statelevel;
	if _n_ = &maxcutoff+1 then call symput("cutoff",maxcase);
run;
proc sql noprint;
	select count(*) into :numk from statelevel where maxcase>&cutoff;
	select distinct province_state into :state1-:state%cmpres(&numk) from statelevel where maxcase>=&cutoff;
	select distinct province_state into :states separated by '","' from statelevel where maxcase>=&cutoff;
quit;


data _graph(keep=filedate province_state &analysisvar &tipvars plotlabel) 
	 _cc(keep=province_state statecolormatch) ; 
	set state_trajectories;
	by province_state filedate;
	if _n_=1 then match=1; 
	if province_state not in ("&states") then do;
		province_state='Other';
	end;
	if filedate >= &startdate;
	if &analysisvar < 1 then &analysisvar=1;
	if last.province_state then do;
		
		if province_state ~= 'Other' then statecolormatch=match;
		else statecolormatch=&othercolor;
		match+1;
		output _cc;
	end;
	plotlabel=substr(province_state,1,2);
	output _graph;
run;

proc sql noprint;
	create table _statecolor as	
		select distinct province_state, b.* 
		from _cc a 
			inner join _colors b 
			on a.statecolormatch=b.value
			;
quit;
		
data _statecolor; set _statecolor(drop=value ) ;
	value=province_state;
run;

proc sql; create table _sgraph as	
select a.*, b.maxcase from _graph a left join statelevel b on a.province_state=b.province_state;
quit;
proc sort data=_sgraph; by maxcase province_state filedate; run;

ods graphics / reset=all width=12in height=8in imagemap=on tipmax=100000  imagefmt=svg;
ods html5  path="graphs" body="stateDaily_Top&maxcutoff..htm" (url=none) options(bitmap_mode="inline");

title 	  "SARS-COV-2: State Contribution per Reporting Date for Top &maxcutoff by Cases";
title2 	  h=1 "Updated &wordDte";
footnote  j=c h=1 "Beware of drawing conclusions from this data beyond the purpose for which it was generated.";
footnote2 j=c h=.95 "Data Source: Johns Hopkins University - https://github.com/CSSEGISandData/COVID-19 Data Updated: &sysdate";
footnote3 j=r h=0.5  "Samuel T. Croker - &sysdate9";

proc sgplot data=_sgraph/*(where=(filedate>='01jul20'd))*/
	des="State Daily Contribution for top &maxcutoff States" dattrmap=_statecolor ;
	vbar Filedate / nooutline
		response=&ANALYSISVAR    
		group=maxcase
		stat=sum 
		grouporder=ascending
		groupdisplay=stack 
		nooutline fillattrs=(transparency=.5)
		tip=(province_state maxcase FileDate &analysisvar &tipvars ) 
		attrid=c_ramp 
		;

	xaxis fitpolicy=rotatethin;
	yaxis ;*type=log offsetmin=1 min=10 values=(10 100 1000 to 10000 by 1000) ;
run;

ods html5 close;
ods graphics / reset;


title;footnote;

