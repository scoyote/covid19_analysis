/*
proc sql;
select distinct location from global_trajectories order by location;
quit;
*/

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


ods html close;ods rtf close;ods pdf close;ods document close;
options orientation=landscape papersize=tabloid  nomprint nomlogic;
ods graphics on / reset width=16in height=10in imagemap outputfmt=svg imagefmt=svg; 


title 	  h=1 "Cases - SARS-CoV-2";
footnote  h=1 "Data Source: Johns Hopkins University - https://github.com/CSSEGISandData/COVID-19  Data Updated: &sysdate";
footnote3 h=0.9 justify=right "Samuel T. Croker - &sysdate9";

proc sgplot data=us_v_eu dattrmap=_regmap noautolegend;
	series x=filedate y=yval /  smoothconnect group=glb datalabel=plotlabel lineattrs=(pattern=solid thickness=2) attrid=regcol;
	series x=filedate y=y2val / y2axis smoothconnect group=glb datalabel=plotlabel lineattrs=(pattern=longdash  thickness=2 ) attrid=regcol;
	yaxis  grid minorgrid offsetmin=1 offsetmax=1 min=0;
	y2axis  			  offsetmin=1 offsetmax=1 min=0 max=9000;
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

title 	  h=1 "Deaths - SARS-CoV-2";
footnote  h=1 "Data Source: Johns Hopkins University - https://github.com/CSSEGISandData/COVID-19  Data Updated: &sysdate";
footnote3 h=0.9 justify=right "Samuel T. Croker - &sysdate9";

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

title 	  h=1 "United States vs European Union SARS-CoV-2 Trajectories";
footnote  h=1 "Data Source: Johns Hopkins University - https://github.com/CSSEGISandData/COVID-19  Data Updated: &sysdate";
footnote3 h=0.9 justify=right "Samuel T. Croker - &sysdate9";

proc sgplot data=us_v_eu(where=(deaths>0 and cases>0))  dattrmap=_regmap noautolegend;
	series x=filedate y=cases/  smoothconnect group=glb datalabel=plotlabel lineattrs=(pattern=solid thickness=2) attrid=regcol;
	series x=filedate y=deaths/ y2axis smoothconnect group=glb datalabel=plotlabel lineattrs=(pattern=longdash  thickness=2 ) attrid=regcol;	
	yaxis   grid minorgrid offsetmin=1 offsetmax=1 min=0;
	y2axis   			   offsetmin=1 offsetmax=1 min=0 ;
	xaxis min='01FEB2020'd offsetmin=0 offsetmax=.1;
	
	refline '25may2020'd /axis=x label="Memorial Day";
run;
quit;


