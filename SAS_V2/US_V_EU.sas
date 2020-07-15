/*
proc sql;
select distinct location from global_trajectories order by location;
quit;
*/
%include "US_V_EU_MACROS.sas";

data _null_ ;call symput("wordDte",trim(left(put("&sysdate9"d, worddatx32.)))); run;

data _raw;
	length glb $50.;
	set global_trajectories;
	if location in ('United Kingdom','Austria', 'Belgium', 'Bulgaria', 'Croatia', 'Cyprus', 'Czechia', 
					'Denmark', 'Estonia', 'Finland', 'France', 'Germany', 'Greece', 'Hungary', 
					'Ireland', 'Italy', 'Latvia', 'Lithuania', 'Luxembourg', 'Malta', 
					'Netherlands', 'Poland', 'Portugal', 'Romania', 'Slovakia', 'Slovenia', 'Spain')
		then glb='European Union';
	else if location in ('Brazil','Peru','Chile','Colombia','Ecuador','Argentina','Bolivia','Venezuela',
	'French Guiana','Paraguay','Uruguay','Suriname','Guyana',' Falkland Islands') 
		then glb='South America';
	else if location in ('Russia','China','India','Iran','Turkey','Pakistan','Saudi Arabia','Bangladesh',
	'Qatar','Indonesia','United Arab Emirates','Sinagpore','Kuwait','Iraq','Oman','Philippines',
	'Afghanistan','Bahrain','Israel','Armenia','Kazakhstan','Japan','Azerbaijan','Korea, South',
	'Nepal','Malaysia','Uzbekistan','Tajikistan','Kyrgyzstan','Thailand','Maldives','Sri Lanka',
	'Lebanon','Hong Kong','Palestine','Jordan','Cyprus','Yemen','Georgia','Taiwan','Vietnam',
	'Myanmar','Syria','Mongolia','Brunei','Cambodia','Bhutan','Macao','Timor-Leste','Laos')
		then glb='Asia';
	else if location in ('South Africa','Egypt','Nigeria','Gabon','Ghana','Cameroon','Algeria','Morocco',
	'Congo','Congo (Brazzaville)','Congo (Kinshasa)','Ivory Coast','Central African Republic','Algeria','Mauritania','Ethiopia','Sudan',
	'Niger','Tunisia','Sierra Leone','Zambia','Guinea-Bissau','Madagascar','Equitorial Guinea',
	'South Sudan','Mali','Mayotte','Somalia') 
		then glb='Africa';
	else if location in ('Australia','New Zealand','Papua New Guinea','French Polynesia','New Caledonia','Fiji') 
		then glb='Oceania';
	else if location in ('Mexico','Panama','Dominican Republic','Guatemala','Honduras','Haiti',
	'El Salvador','Cuba','Costa Rica','Nicaragua','Jamaica','Martinique','Cayman Islands','Guadeloupe','Bermuda','Trinidad and Tobago','Bahamas',
	'Aruba','Barbados','Sint Maarten','Saint Martin','Saint Vincent and the Grenadines','Saint Kitts and Nevis',
	'Antigua and Barbuda', 'Curacao') 
		then glb='Central America';
	else if location = 'US' then glb='US';
	else if location = 'Sweden' then glb='Sweden';
	else glb='Other';
	
/* 	if glb ~='OT' then output; */
run;

proc sql noprint;
	create table _summary as	
	select filedate,glb,sum(confirmed) as confirmed, sum(deaths) as deaths
	from _raw
	group by filedate, glb
	order by glb, filedate;
quit;


proc expand data= _summary out=_e1;
	by glb;
	id filedate;
	convert confirmed	= dif1_confirmed / transout=(dif 1);
	convert confirmed	= dif7_confirmed / transout=(dif 7);
	convert confirmed	= MA7_confirmed  / transout=(movave 7);
	convert deaths		= dif1_deaths 	 / transout=(dif 1);
	convert deaths		= dif7_deaths	 / transout=(dif 7);	
	convert deaths		= MA7_deaths 	 / transout=(movave 7);
run;
proc expand data=_e1 out=_us_v_eu;
	by glb;
	id filedate;
	convert dif1_confirmed	= MA7_new_confirmed  / transout=(movave 7);
	convert dif1_deaths		= ma7_new_deaths 	 / transout=(movave 7);
run;
proc sort data=_us_v_eu; by glb filedate; run;


%let target=ma7_new_confirmed;
%let targetlabel='Cases 7 Day Moving Average';

data us_v_eu; set _us_v_eu;
	by glb filedate;
	label glb ="Consolodated Location";
	dif1_confirmed=ceil(dif1_confirmed);
	dif7_confirmed=ceil(dif7_confirmed);
	dif1_deaths=ceil(dif1_deaths);
	dif7_deaths=ceil(dif7_deaths);
	ma7_confirmed=ceil(ma7_confirmed);
	ma7_deaths=ceil(ma7_deaths);
	
	MA7_new_confirmed=ceil(MA7_new_confirmed);
	MA7_new_deaths=ceil(MA7_new_deaths);
	if last.glb then plotlabel=glb; 
	else plotlabel="";
	yval=ma7_new_confirmed;
	format yval y2val comma12.;
	if glb in ('Sweden','Oceania','Other','Central America','Africa') then do;
		y2val=&target;
		yval=.;
	end;
	else do;
		yval =&target;
		y2val=.;
	end;
	if first.glb then do;
		yval=0;
		y2val=0;
	end;
	label yval=&targetlabel;
	label y2val=&targetlabel;

run;


data _regmap;
	informat id $20. value $50. linecolor symbol $30. color $50.;
	ID='regcol';value = 'US'; 				color	= 'darkred'; 	linecolor=color; output;
	ID='regcol';value = 'European Union'; 	color	= 'darkblue';  	linecolor=color; output;
	ID='regcol';value = 'Asia'; 			color	= 'darkgreen';  linecolor=color; output;
	ID='regcol';value = 'Africa'; 			color	= 'royalblue';  linecolor=color; output;
	ID='regcol';value = 'South America';	color	= 'SeaGreen'; 	linecolor=color; output;
	ID='regcol';value = 'Central America'; 	color	= 'olive';  	linecolor=color; output;
	ID='regcol';value = 'Oceania'; 			color	= 'indigo'; 	linecolor=color; output;
	ID='regcol';value = 'Other'; 			color	= 'lightgray'; 	linecolor=color; output;
	ID='regcol';value = 'Sweden'; 			color	= 'lightred'; 	linecolor=color; output;
run;

proc sql noprint ;
	select int(max(y2val)+0.05*max(y2val)) into :y2max from us_v_eu;
quit;

ods html close;ods rtf close;ods pdf close;ods document close;
options orientation=landscape papersize=tabloid  nomprint nomlogic;
ods graphics on / reset width=16in height=10in imagemap outputfmt=svg imagefmt=svg; 
ods html5  body="US_VS_Others.htm" (url=none) options(svg_mode="inline");


title 	  "SARS-CoV-2: Confirmed Cases in Major Population Areas Compared";
title2 	  h=1 "Updated &wordDte";
footnote   j=c "Dashed lines correspond to the right axis for phase comparison.";
footnote2  j=c h=1 "Beware of drawing conclusions from this data beyond the purpose for which it was generated.";
footnote3 j=c h=.95 "Data Source: Johns Hopkins University - https://github.com/CSSEGISandData/COVID-19 Data Updated: &sysdate";
footnote4 j=r h=0.5  "Samuel T. Croker - &sysdate9";

proc sgplot data=us_v_eu dattrmap=_regmap noautolegend;
	series x=filedate y=yval /  smoothconnect group=glb datalabel=plotlabel lineattrs=(pattern=solid thickness=2) attrid=regcol;
	series x=filedate y=y2val / y2axis smoothconnect group=glb datalabel=plotlabel lineattrs=(pattern=longdash  thickness=2 ) attrid=regcol;
	yaxis  grid minorgrid offsetmin=1 offsetmax=1 min=0;
	y2axis  			  offsetmin=1 offsetmax=1 min=0 max=&y2max;
	xaxis min='01FEB2020'd offsetmin=0 offsetmax=.1;
	
	refline '25may2020'd /axis=x label="Memorial Day";
run;
quit;



%let target=ma7_new_deaths;
%let targetlabel='Deaths 7 Day Moving Average';

data us_v_eu; set _us_v_eu;
	by glb filedate;
	label glb ="Consolodated Location";
	dif1_confirmed=ceil(dif1_confirmed);
	dif7_confirmed=ceil(dif7_confirmed);
	dif1_deaths=ceil(dif1_deaths);
	dif7_deaths=ceil(dif7_deaths);
	ma7_confirmed=ceil(ma7_confirmed);
	ma7_deaths=ceil(ma7_deaths);
	
	MA7_new_confirmed=ceil(MA7_new_confirmed);
	MA7_new_deaths=ceil(MA7_new_deaths);
	if last.glb then plotlabel=glb; 
	else plotlabel="";
	yval=ma7_new_confirmed;
	format yval y2val comma12.;
	if glb in ('Sweden','Oceania','Other','Africa') then do;
		y2val=&target;
		yval=.;
	end;
	else do;
		yval =&target;
		y2val=.;
	end;
	if first.glb then do;
		yval=0;
		y2val=0;
	end;
	label yval=&targetlabel;
	label y2val=&targetlabel;

run;

title 	  "SARS-CoV-2: Deaths in Major Population Areas Compared";
title2 	  h=1 "Updated &wordDte";

proc sgplot data=us_v_eu dattrmap=_regmap noautolegend;
	series x=filedate y=yval /  smoothconnect group=glb datalabel=plotlabel lineattrs=(pattern=solid thickness=2) attrid=regcol;
	series x=filedate y=y2val / y2axis smoothconnect group=glb datalabel=plotlabel lineattrs=(pattern=longdash  thickness=2 ) attrid=regcol;
	yaxis  grid minorgrid offsetmin=1 offsetmax=1 min=0;
	y2axis  			  offsetmin=1 offsetmax=1 min=0 ;
	xaxis min='01FEB2020'd offsetmin=0 offsetmax=.1;
	
	refline '25may2020'd /axis=x label="Memorial Day";
run;
quit;










data us_v_eu; set _us_v_eu;
	by glb filedate;
	label glb ="Consolodated Location";
	dif1_confirmed=ceil(dif1_confirmed);
	dif7_confirmed=ceil(dif7_confirmed);
	dif1_deaths=ceil(dif1_deaths);
	dif7_deaths=ceil(dif7_deaths);
	ma7_confirmed=ceil(ma7_confirmed);
	ma7_deaths=ceil(ma7_deaths);
	
	MA7_new_confirmed=ceil(MA7_new_confirmed);
	MA7_new_deaths=ceil(MA7_new_deaths);
	if last.glb then plotlabel=glb; 
	else plotlabel="";
	
	deaths	=ma7_new_deaths;
	cases	=ma7_new_confirmed;
	format deaths cases comma12.;
	label deaths="Deaths 7 Day Moving Average";
	label cases="Cases 7 Day Moving Average";
	label filedate="Report Date";
	if glb in ("US","European Union") then output;
run;

title 	  "SARS-CoV-2: US Cases and Deaths vs European Union Cases and Deaths";
title2 	  h=1 "Updated &wordDte";
footnote   j=c h=0.9 "Cases are solid lines corresponding to the left axis, and deaths are dashed lines corresponding to the right axis for phase comparison.";
footnote2  j=c h=1 "Beware of drawing conclusions from this data beyond the purpose for which it was generated.";
footnote3 j=c h=.95 "Data Source: Johns Hopkins University - https://github.com/CSSEGISandData/COVID-19 Data Updated: &sysdate";
footnote4 j=r h=0.5  "Samuel T. Croker - &sysdate9";

proc sgplot data=us_v_eu(where=(deaths>0 and cases>0))  dattrmap=_regmap noautolegend;
	series x=filedate y=cases/  smoothconnect group=glb datalabel=plotlabel lineattrs=(pattern=solid thickness=2) attrid=regcol;
	series x=filedate y=deaths/ y2axis smoothconnect group=glb datalabel=plotlabel lineattrs=(pattern=longdash  thickness=2 ) attrid=regcol;	
	yaxis   grid minorgrid offsetmin=1 offsetmax=1 min=0;
	y2axis   			   offsetmin=1 offsetmax=1 min=0 ;
	xaxis min='01FEB2020'd offsetmin=0 offsetmax=.1;
	
	refline '25may2020'd /axis=x label="Memorial Day";
run;
quit;




title 	  "SARS-CoV-2: US Cases and Deaths ";
title2 	  h=1 "Updated &wordDte";
footnote   j=c h=0.9 "Cases are solid lines corresponding to the left axis, and deaths are dashed lines corresponding to the right axis for phase comparison.";
footnote2  j=c h=1 "Beware of drawing conclusions from this data beyond the purpose for which it was generated.";
footnote3 j=c h=.95 "Data Source: Johns Hopkins University - https://github.com/CSSEGISandData/COVID-19 Data Updated: &sysdate";
footnote4 j=r h=0.5  "Samuel T. Croker - &sysdate9";

proc sgplot data=us_v_eu(where=(deaths>0 and cases>0 and glb='US'))  dattrmap=_regmap noautolegend;
	series x=filedate y=cases/  smoothconnect group=glb datalabel=plotlabel lineattrs=(pattern=solid thickness=2) attrid=regcol;
	series x=filedate y=deaths/ y2axis smoothconnect group=glb datalabel=plotlabel lineattrs=(pattern=longdash  thickness=2 ) attrid=regcol;	
	yaxis   grid minorgrid offsetmin=1 offsetmax=1 min=0;
	y2axis   			   offsetmin=1 offsetmax=1 min=0 ;
	xaxis min='01FEB2020'd offsetmin=0 offsetmax=.1;
	
	refline '25may2020'd /axis=x label="Memorial Day";
run;
quit;





data _raw;
	length glb $50.;
	set global_trajectories;
	if location ="Germany" then glb='Germany';
/* 	else if location ='Korea, South' then glb='South Korea'; */
	else if location = 'US' then glb='US';
	else if location = 'Sweden' then glb='Sweden';
	else if location in ("UK",'United Kingdom') then glb='UK';
	else delete;
	
/* 	if glb ~='OT' then output; */
run;

proc sql noprint;
	create table _summary as	
	select filedate,glb,sum(confirmed) as confirmed, sum(deaths) as deaths
	from _raw
	group by filedate, glb
	order by glb, filedate;
quit;


proc expand data= _summary out=_e1;
	by glb;
	id filedate;
	convert confirmed	= dif1_confirmed / transout=(dif 1);
	convert confirmed	= dif7_confirmed / transout=(dif 7);
	convert confirmed	= MA7_confirmed  / transout=(movave 7);
	convert deaths		= dif1_deaths 	 / transout=(dif 1);
	convert deaths		= dif7_deaths	 / transout=(dif 7);	
	convert deaths		= MA7_deaths 	 / transout=(movave 7);
run;
proc expand data=_e1 out=_us_v_eu;
	by glb;
	id filedate;
	convert dif1_confirmed	= MA7_new_confirmed  / transout=(movave 7);
	convert dif1_deaths		= ma7_new_deaths 	 / transout=(movave 7);
run;
proc sort data=_us_v_eu; by glb filedate; run;


%let target=ma7_new_confirmed;
%let targetlabel='Cases per 100,000 - 7 Day Moving Average';

data us_v_eu; set _us_v_eu;
	by glb filedate;
	label glb ="Consolodated Location";
	dif1_confirmed=ceil(dif1_confirmed);
	dif7_confirmed=ceil(dif7_confirmed);
	dif1_deaths=ceil(dif1_deaths);
	dif7_deaths=ceil(dif7_deaths);
	ma7_confirmed=ceil(ma7_confirmed);
	ma7_deaths=ceil(ma7_deaths);
	
	MA7_new_confirmed=ceil(MA7_new_confirmed);
	MA7_new_deaths=ceil(MA7_new_deaths);
	if last.glb then plotlabel=glb; 
	else plotlabel="";
	yval=ma7_new_confirmed;
	format yval y2val comma12.;
	if glb='US' then do;
		MA7_new_confirmed=MA7_new_confirmed/328200000;
		MA7_new_deaths=MA7_new_deaths/328200000;
	end;
	else if glb='Germany' then do;
		MA7_new_confirmed=MA7_new_confirmed/83020000;
		MA7_new_deaths=MA7_new_deaths/83020000;
	end;
	else if glb='UK' then do;
		MA7_new_confirmed=MA7_new_confirmed/66650000;
		MA7_new_deaths=MA7_new_deaths/66650000;
	end;
	else if glb='Sweden' then do;
		MA7_new_confirmed=MA7_new_confirmed/10230000;
		MA7_new_deaths=MA7_new_deaths/10230000;
	end;
	else if glb='South Korea' then do;
		MA7_new_confirmed=MA7_new_confirmed/51640000;
		MA7_new_deaths=MA7_new_deaths/51640000;
	end;
	yval =MA7_new_confirmed*1e6;
	y2val = MA7_new_deaths*1e6;
	
	label yval="Cases per 100,000 - 7 Day Moving Average";
	label y2val="Deaths per 100,000 - 7 Day Moving Average";

run;


data _regmap;
	informat id $20. value $50. linecolor symbol $30. color $50.;
	ID='regcol';value = 'US'; 			color	= 'darkred'; 	linecolor=color; output;
	ID='regcol';value = 'Germany'; 		color	= 'darkblue';  	linecolor=color; output;
	ID='regcol';value = 'South Korea'; 	color	= 'darkgreen';  linecolor=color; output;
	ID='regcol';value = 'UK'; 			color	= 'royalblue';  linecolor=color; output;
	ID='regcol';value = 'South America';	color	= 'SeaGreen'; 	linecolor=color; output;
	ID='regcol';value = 'Central America'; 	color	= 'olive';  	linecolor=color; output;
	ID='regcol';value = 'Oceania'; 			color	= 'indigo'; 	linecolor=color; output;
	ID='regcol';value = 'Other'; 			color	= 'lightgray'; 	linecolor=color; output;
	ID='regcol';value = 'Sweden'; 			color	= 'lightred'; 	linecolor=color; output;
run;


proc sql noprint ;
	select int(max(y2val)+0.05*max(y2val)) into :y2max from us_v_eu;
quit;

options orientation=landscape papersize=tabloid  nomprint nomlogic;
ods graphics on / reset width=16in height=10in imagemap outputfmt=svg imagefmt=svg; 

title 	  "SARS-CoV-2: Confirmed Cases per 100,000 in Selected Regions";
title2 	  h=1 "Updated &wordDte";
footnote1  j=c h=1 "Beware of drawing conclusions from this data beyond the purpose for which it was generated.";
footnote2 j=c h=.95 "Data Source: Johns Hopkins University - https://github.com/CSSEGISandData/COVID-19 Data Updated: &sysdate";
footnote3 j=r h=0.5  "Samuel T. Croker - &sysdate9";
proc sgplot data=us_v_eu dattrmap=_regmap noautolegend;
	series x=filedate y=yval /  smoothconnect group=glb datalabel=plotlabel lineattrs=(pattern=solid thickness=2) attrid=regcol;
	yaxis  grid minorgrid offsetmin=1 offsetmax=1 min=0;
	y2axis  			  offsetmin=1 offsetmax=1 min=0 ;
	xaxis min='01mar2020'd offsetmin=0 offsetmax=.1;
	refline 15 /axis=y label="15 Cases per 100k-Probable EU Cutoff-for Admission"  splitchar='-' lineattrs=(color=royalblue) labelloc=inside;
	refline '25may2020'd 	/axis=x label="Memorial Day" 		lineattrs=(color=darkred)  labelloc=inside;
/* 	refline '16mar2020'd 	/axis=x label="German Shutdown P0" 	lineattrs=(color=darkblue) labelloc=outside ; */
/* 	refline '22mar2020'd 	/axis=x label="German Shutdown P1" 	lineattrs=(color=darkblue) labelloc=inside; */
	refline '06may2020'd 	/axis=x label="German Reopen P0" 	lineattrs=(color=darkblue) labelloc=outside;
/* 	refline '15jun2020'd 	/axis=x label="UK Retail" 			lineattrs=(color=royalblue) labelloc=inside; */
	refline '04JUL2020'd 	/axis=x label="UK Pubs, Dining" 	lineattrs=(color=royalblue) labelloc=outside ;
run;
quit;

title 	  "SARS-CoV-2: Deaths per 100,000 in Selected Regions";
title2 	  h=1 "Updated &wordDte";
proc sgplot data=us_v_eu dattrmap=_regmap noautolegend;
	series x=filedate y=y2val / smoothconnect group=glb datalabel=plotlabel lineattrs=(pattern=solid thickness=2 ) attrid=regcol;
	yaxis  grid minorgrid offsetmin=1 offsetmax=1 min=0;
	xaxis min='01mar2020'd offsetmin=0 offsetmax=.1;
/* 	refline '25may2020'd 	/axis=x label="Memorial Day" 		lineattrs=(color=darkred) labelloc=inside; */
/* 	refline '16mar2020'd 	/axis=x label="German PH1" 			lineattrs=(color=darkblue) labelloc=inside; */
/* 	refline '22mar2020'd 	/axis=x label="German Shutdown" 	lineattrs=(color=darkblue) labelloc=inside labelpos=min; */
/* 	refline '06may2020'd 	/axis=x label="German Reopen P0" 	lineattrs=(color=darkblue) labelloc=inside;	 */
/* 	refline '15jun2020'd 	/axis=x label="UK Retail" 			lineattrs=(color=royalblue) labelloc=inside; */
/* 	refline '04JUL2020'd 	/axis=x label="UK Pubs, Dining" 	lineattrs=(color=royalblue) labelloc=outside; */
run;
quit;

proc sql;
	create table topfips as
	select combined_key as County, fips as FIPS, ma7_new_confirmed/census2010pop*1e5 as casesPer100k label='Cases per 100k' format=comma10.1, census2010pop format=comma12.
	from fips_trajectories 
	where filedate='12jul20'd
	  and census2010pop >= 1e5
	order by  ma7_new_confirmed/census2010pop*1e5 descending
	;
quit;
proc print data=topfips (obs=100);
	label casesper100k="Cases per 100k";
	label census2010pop='2010 Population';
run;

/* ,'45035' ,'45083','45085','36047','36081','36005'*/

data GAfips; set fips_trajectories(where=(fips in ('13057','13067','13121'
													,'48029','48355','48167'
													,'45007','45015','45019','45013''45063','45045','45051'
/* 													,'36061' */
													,'37067'
													,'12086')));
	
	yval=ma7_new_confirmed/census2010pop*1e5;
	y2val=deaths/census2010pop*1e5;
	if filedate>='01jun20'd;
	label yval='Cases per 100,000';
	label y2val='Deaths per 100,000';
run;
proc sort data=gafips; by fips combined_key; run;
data gafips; set gafips;
by fips province_state;
if last.fips then plotlabel=combined_key;
keep filedate plotlabel yval y2val fips combined_key;
run;

title 	  "SARS-CoV-2: Confirmed Cases per 100,000 in Selected Regions";
title2 	  h=1 "Updated &wordDte";
footnote1  j=c h=1 "Beware of drawing conclusions from this data beyond the purpose for which it was generated.";
footnote2 j=c h=.95 "Data Source: Johns Hopkins University - https://github.com/CSSEGISandData/COVID-19 Data Updated: &sysdate";
footnote3 j=r h=0.5  "Samuel T. Croker - &sysdate9";
proc sgplot data=gafips noautolegend;
	series x=filedate y=yval /  smoothconnect group=fips datalabel=plotlabel lineattrs=(pattern=solid thickness=2) tip=(combined_key fips yval);
	yaxis  grid minorgrid offsetmin=1 offsetmax=1 min=0;
	y2axis  			  offsetmin=1 offsetmax=1 min=0 ;
	xaxis min='01jun2020'd offsetmin=0 offsetmax=.1;
/* 	refline 15 /axis=y label="15 Cases per 100k-Probable EU Cutoff-for Admission"  splitchar='-' lineattrs=(color=royalblue) labelloc=inside; */
run;
quit;

proc sgplot data=gafips(where=(fips in ('13057'))) noautolegend;
	series x=filedate y=yval /  smoothconnect group=fips datalabel=plotlabel lineattrs=(pattern=solid thickness=2) tip=(combined_key fips yval);
	yaxis  grid minorgrid offsetmin=1 offsetmax=1 min=0;
	y2axis  			  offsetmin=1 offsetmax=1 min=0 ;
	xaxis min='01jun2020'd offsetmin=0 offsetmax=.1;
/* 	refline 15 /axis=y label="15 Cases per 100k-Probable EU Cutoff-for Admission"  splitchar='-' lineattrs=(color=royalblue) labelloc=inside; */
run;
quit;


proc sql noprint;
	select max(y2val) into :y2max from gafips;
quit;
title 	  "SARS-CoV-2: Deaths per 100,000 in Selected Regions";
title2 	  h=1 "Updated &wordDte";
proc sgplot data=gafips  noautolegend;
	series x=filedate y=y2val / smoothconnect group=fips datalabel=plotlabel lineattrs=(pattern=solid thickness=2 ) ;
	yaxis  grid minorgrid offsetmin=1 offsetmax=1 min=0 max=&y2max;
	xaxis min='01jun2020'd offsetmin=0 offsetmax=.1;
run;
quit;




data states; set state_trajectories;
	yval=ma7_new_confirmed/census2010pop*1e5;
	label yval='Cases per 100,000';
	y2val=deaths/census2010pop*1e5;
	label y2val='Deaths per 100,000';
	
run;
proc sort data=states; by province_state; run;
data states; set states;
	by province_state;
	if last.province_state then plotlabel=province_state;
	keep filedate plotlabel yval y2val province_state;
run;

title 	  "SARS-CoV-2: Confirmed Cases per 100,000 in US States";
title2 	  h=1 "Updated &wordDte";
footnote1  j=c h=1 "Beware of drawing conclusions from this data beyond the purpose for which it was generated.";
footnote2 j=c h=.95 "Data Source: Johns Hopkins University - https://github.com/CSSEGISandData/COVID-19 Data Updated: &sysdate";
footnote3 j=r h=0.5  "Samuel T. Croker - &sysdate9";
proc sgplot data=states noautolegend;
	series x=filedate y=yval /  smoothconnect group=province_state datalabel=plotlabel lineattrs=(pattern=solid thickness=2) tip=(province_state yval);
	yaxis  grid minorgrid offsetmin=1 offsetmax=1 min=0;
	y2axis  			  offsetmin=1 offsetmax=1 min=0 ;
	xaxis min='01jun2020'd offsetmin=0 offsetmax=.1;
run;
quit;


data cbsas; set cbsa_trajectories;
	yval=ma7_new_confirmed/census2010pop*1e5;
	y2val=deaths/census2010pop*1e5;

	label yval='Cases per 100,000';
	label y2val='Deaths per 100,000';
run;
proc sql noprint;
	create table cbsamax as
	select cbsa_title, max(yval) as maxcbsa ,max(census2010pop) as pop
	from cbsas
	group by  cbsa_title
	order by maxcbsa desc;
data cbsamax;
	set cbsamax;
	if _n_=1 then rank=0;
	if pop>750000 then rank+1;
	else delete;
run;
proc sql noprint; select distinct cbsa_title into :cbsas separated by '","' from cbsamax;
quit;
proc sort data=cbsas; by CBSA_TITLE filedate; run;
data cbsas; set cbsas;
	by CBSA_TITLE;
	if cbsa_title in ("&cbsas");
	if last.CBSA_TITLE then plotlabel=CBSA_TITLE;
	keep filedate plotlabel yval y2val CBSA_TITLE;
run;

title 	  "SARS-CoV-2: Confirmed Cases per 100,000 in US CBSAs";
title2 	  h=1 "Updated &wordDte";
footnote1  j=c h=1 "Beware of drawing conclusions from this data beyond the purpose for which it was generated.";
footnote2 j=c h=.95 "Data Source: Johns Hopkins University - https://github.com/CSSEGISandData/COVID-19 Data Updated: &sysdate";
footnote3 j=r h=0.5  "Samuel T. Croker - &sysdate9";
proc sgplot data=cbsas noautolegend;
	series x=filedate y=yval /  smoothconnect group=CBSA_TITLE datalabel=plotlabel lineattrs=(pattern=solid thickness=2) tip=(CBSA_TITLE yval);
	yaxis  grid minorgrid offsetmin=1 offsetmax=1 min=0;
	y2axis  			  offsetmin=1 offsetmax=1 min=0 ;
	xaxis min='01jun2020'd offsetmin=0 offsetmax=.1;
run;
quit;


ods html close;


