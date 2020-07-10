%let target=California;

ods graphics on / reset width=10in height=7in imagemap outputfmt=svg imagefmt=svg tipmax=100000 ; 
data _null_ ;call symput("wordDte",trim(left(put("&sysdate9"d, worddatx32.)))); run;
%put worddte[&wordDte];

title 	  "&target SARS-CoV-2 Cases and Deaths";
title2 	  h=1 "Updated &wordDte";
footnote  j=c h=1 "Beware of drawing conclusions from this data beyond the purpose for which it was generated.";
footnote2 j=c h=.95 "Data Source: Johns Hopkins University - https://github.com/CSSEGISandData/COVID-19 Data Updated: &sysdate";
footnote3 j=r h=0.5  "Samuel T. Croker - &sysdate9";
footnote4 h=1 j=c "Dashed lines correspond to the RIGHT axis, while solid lines correspond to the LEFT axis.";

proc sgplot data=state_trajectories(where=(filedate>'01mar20'd and ma7_new_confirmed>0 and ma7_new_deaths>0 and province_state="&target")) ;
	series x=filedate y=ma7_new_confirmed/  smoothconnect  lineattrs=(pattern=solid thickness=2) attrid=regcol;
	series x=filedate y=ma7_new_deaths/ y2axis smoothconnect  lineattrs=(pattern=longdash  thickness=2 ) ;	
	yaxis  type=linear grid minorgrid min=1;
	y2axis type=linear		    	   min=1;
	xaxis  min='01FEB2020'd ;
/* 	refline (&umax1c ) /axis=x label= "US Max Case" lineattrs=(color=darkred ); */
/* 	refline (&umin2 ) /axis=x label= "US Min Case" lineattrs=(color=darkred ); */
run;
quit;
proc sgplot data=global_trajectories(where=(filedate>'01mar20'd and ma7_new_confirmed>0 and ma7_new_deaths>0 and location="US")) ;
	series x=filedate y=ma7_new_confirmed/  smoothconnect  lineattrs=(pattern=solid thickness=2) attrid=regcol;
	series x=filedate y=ma7_new_deaths/ y2axis smoothconnect  lineattrs=(pattern=longdash  thickness=2 ) ;	
	yaxis  type=linear grid minorgrid min=1;
	y2axis type=linear		    	   min=1;
	xaxis  min='01FEB2020'd ;
/* 	refline (&umax1c ) /axis=x label= "US Max Case" lineattrs=(color=darkred ); */
/* 	refline (&umin2 ) /axis=x label= "US Min Case" lineattrs=(color=darkred ); */
run;
quit;
ods html5 close;
ods graphics / reset=all;
title; footnote;