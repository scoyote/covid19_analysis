
%let codepath=/repositories/covid19_analysis/SAS_V2/Demonstration;
%let rc = %sysfunc(dlgcdir("&codepath")); 
%include 'MACROS.sas';

libname pCovid '/repositories/covid19_analysis/SAS_V2/data';

data _null_ ;call symput("wordDte",trim(left(put("&sysdate9"d, worddatx32.)))); run;

data _raw;
	length glb $50.;
	set pcovid.gl_daily;
	if country_region in ('United Kingdom','Austria', 'Belgium', 'Bulgaria', 'Croatia', 'Cyprus', 'Czechia', 
					'Denmark', 'Estonia', 'Finland', 'France', 'Germany', 'Greece', 'Hungary', 
					'Ireland', 'Italy', 'Latvia', 'Lithuania', 'Luxembourg', 'Malta', 
					'Netherlands', 'Poland', 'Portugal', 'Romania', 'Slovakia', 'Slovenia', 'Spain')
		then glb='European Union';
	else if country_region in ('Brazil','Peru','Chile','Colombia','Ecuador','Argentina','Bolivia','Venezuela',
	'French Guiana','Paraguay','Uruguay','Suriname','Guyana',' Falkland Islands') 
		then glb='South America';
	else if country_region in ('Russia','China','India','Iran','Turkey','Pakistan','Saudi Arabia','Bangladesh',
	'Qatar','Indonesia','United Arab Emirates','Sinagpore','Kuwait','Iraq','Oman','Philippines',
	'Afghanistan','Bahrain','Israel','Armenia','Kazakhstan','Japan','Azerbaijan','Korea, South',
	'Nepal','Malaysia','Uzbekistan','Tajikistan','Kyrgyzstan','Thailand','Maldives','Sri Lanka',
	'Lebanon','Hong Kong','Palestine','Jordan','Cyprus','Yemen','Georgia','Taiwan','Vietnam',
	'Myanmar','Syria','Mongolia','Brunei','Cambodia','Bhutan','Macao','Timor-Leste','Laos')
		then glb='Asia';
	else if country_region in ('South Africa','Egypt','Nigeria','Gabon','Ghana','Cameroon','Algeria','Morocco',
	'Congo','Congo (Brazzaville)','Congo (Kinshasa)','Ivory Coast','Central African Republic','Algeria','Mauritania','Ethiopia','Sudan',
	'Niger','Tunisia','Sierra Leone','Zambia','Guinea-Bissau','Madagascar','Equitorial Guinea',
	'South Sudan','Mali','Mayotte','Somalia') 
		then glb='Africa';
	else if country_region in ('Australia','New Zealand','Papua New Guinea','French Polynesia','New Caledonia','Fiji') 
		then glb='Oceania';
	else if country_region in ('Mexico','Panama','Dominican Republic','Guatemala','Honduras','Haiti',
	'El Salvador','Cuba','Costa Rica','Nicaragua','Jamaica','Martinique','Cayman Islands','Guadeloupe','Bermuda','Trinidad and Tobago','Bahamas',
	'Aruba','Barbados','Sint Maarten','Saint Martin','Saint Vincent and the Grenadines','Saint Kitts and Nevis',
	'Antigua and Barbuda', 'Curacao') 
		then glb='Central America';
	else if country_region = 'US' then glb='US';
	else if country_region = 'Sweden' then glb='Sweden';
	else glb='Other';
run;
%let targetfield=glb;
%let begindate='01mar2020'd;
%let dataset=_raw;
proc sql noprint;
	create table _graph as	
		select reportdate label='Report Date'
			,&targetfield
			,int(sum(sum(dailyconfirmed,0))) as dailyconfirmed format=comma12.
			,int(sum(sum(dailydeaths,0))) as dailydeaths format=comma12.
			,int(sum(sum(confirmed,0))) as confirmed format=comma12.
			,int(sum(sum(deaths,0))) as deaths format=comma12.
			,int(sum(sum(ma7_cases,0))) as ma7_cases format=comma12. label= 'Cases 7 Day Moving Average'
			,int(sum(sum(ma7_deaths,0))) as ma7_deaths format=comma12. label= 'Deaths 7 Day Moving Average'
			,sum(population) as population format=comma12. label='Population'
			,int(sum(sum(ma7_deaths,0)))/int(sum(sum(ma7_cases,0))) as empirical_ma7_death_rate format=percent6.3
			,int(sum(sum(ma7_cases,0)))/sum(population)*1e5 as cases_ma7_per100k format=comma12.3
			,int(sum(sum(ma7_deaths,0)))/sum(population)*1e5 as deaths_ma7_per100k format=comma12.3
			,put(reportdate,DOWNAME3.) as fd_weekday
		from &dataset
		where reportdate>=&begindate
		group by &targetfield
		,reportdate
		order by &targetfield
		,reportdate
		;
	select min(reportdate) into :minreportdate from _graph;
	select max(reportdate) into :maxreportdate from _graph;
	
quit;
data _graph; 
	set _graph;
	by glb;
	if last.glb then plotlabel=glb;
run;


options papersize=legal orientation=landscape nosymbolgen nomlogic nomprint;
ods graphics on / reset width=13.5in height=8in imagemap outputfmt=svg imagefmt=svg; 

title 	  "SARS-CoV-2: US Cases and Deaths ";
title2 	  h=1 "Updated &wordDte";
footnote   j=c h=0.9 "Cases are solid lines corresponding to the left axis, and deaths are dashed lines corresponding to the right axis for phase comparison.";
footnote2  j=c h=1 "Beware of drawing conclusions from this data beyond the purpose for which it was generated.";
footnote3 j=c h=.95 "Data Source: Johns Hopkins University - https://github.com/CSSEGISandData/COVID-19 Data Updated: &sysdate";
footnote4 j=r h=0.5  "Samuel T. Croker - &sysdate9";

proc sgplot data=_graph noautolegend;
	series x=reportdate y=ma7_cases/  smoothconnect group=glb datalabel=plotlabel lineattrs=(pattern=solid thickness=2) ;
	series x=reportdate y=ma7_deaths/ y2axis smoothconnect group=glb datalabel=plotlabel lineattrs=(pattern=longdash  thickness=2 ) ;	
	yaxis   grid minorgrid min=0;
	y2axis   			   min=0 ;
	xaxis min='01FEB2020'd offsetmin=0 offsetmax=.1;
	where glb='US';* or glb='European Union' or glb='South America';
	refline '25may2020'd /axis=x label="Memorial Day";
	refline '20Jun2020'd /axis=x label='Tulsa Rally';
	refline '30Jul2020'd /axis=x label="Herman Cain-Death" splitchar='-';
	refline '19Aug2020'd /axis=x label="Projected Death-Max (STC7/30)" splitchar='-';
run;
quit;



%let independent=ma7_cases;
%let dependent	=ma7_deaths;
/* %let independent=dailyconfirmed; */
/* %let dependent	=dailydeaths; */

proc arima data=_graph(where=(glb='US' and reportdate>='01mar20'd));
	identify var=&independent(1,7) scan esacf minic;
	run;
	estimate p=(1 2 3 4)(7 8 9) method=ml ;
	run;
	identify var=&dependent crosscorr=&independent scan esacf minic nlag=60;
	run;
	estimate p=3 q=1 input=(26 $ (1)/ &independent) method=ml;
	run;
quit;



proc hpfdiagnose data=_graph(where=(glb='US' and reportdate>='01mar20'd)) 
	print=all
     rep=work.diagcomb1
     outest=diagest 
     criterion=mape 
     delayinput=15
     OUTPROCINFO=opi
     ;
   id reportdate interval=day;
   input &independent  / required=no ;
   forecast &dependent;
   esm;
   arimax   ;
   ucm;
   combine method=average encompass=ols misspercent=25 hormisspercent=50;
run;

proc hpfengine data=_graph(where=(glb='US' and reportdate>='01mar20'd))
     rep=work.diagcomb1
     inest=diagest
     out=outcomb
     outfor=forcomb
     outest=estcomb
     outstatselect=selcomb
     print=all
     back=1
     lead=40;
   id reportdate interval=day;
   forecast &dependent  ;
   input &independent /required=no;
run;

title 	  "SARS-CoV-2: US Cases and Deaths ";
title2 	  h=1 "Updated &wordDte";
footnote   j=c h=0.9 "Cases are solid lines corresponding to the left axis, and deaths are dashed lines corresponding to the right axis for phase comparison.";
footnote2  j=c h=1 "Beware of drawing conclusions from this data beyond the purpose for which it was generated.";
footnote3 j=c h=.95 "Data Source: Johns Hopkins University - https://github.com/CSSEGISandData/COVID-19 Data Updated: &sysdate";
footnote4 j=r h=0.5  "Samuel T. Croker - &sysdate9";

proc sgplot data=forcomb noautolegend;
	band x=reportdate upper=upper lower=lower / transparency=0.5;
	series  x=reportdate y=predict / lineattrs=(color=darkblue thickness=2);
	scatter x=reportdate y=actual / markerattrs=(color=darkred);
	yaxis   grid minorgrid min=0;
	xaxis min='01FEB2020'd offsetmin=0 offsetmax=.1;
	refline '25may2020'd /axis=x label="Memorial Day";
	refline '20Jun2020'd /axis=x label='Tulsa Rally';
	refline '30Jul2020'd /axis=x label="Herman Cain-Death" splitchar='-';
	refline '19Aug2020'd /axis=x label="Projected Death-Max (STC7/30)" splitchar='-';
run;
quit;



