
%let region=Dougherty County;
proc sql noprint;
	create table toregress as
	select *
		,monotonic() as timeperiod
		from JHU_All_Timeseries_Census 
		where census_county like "&region"
		order by filedate
	;
	select distinct population_estimate format=best12. into :popestimate  from toregress;
quit;

%put NOTE: Preparing to estimate &region using maxpop=&popestimate;

/*
	K is the theoretical upper limit for the quantity Y. 
		It is called the carrying capacity in population dynamics.
	r is the rate of maximum growth.
	b is a time offset. The time t = b is the time at which the 
		quantity is half of its maximum value.
*/

proc nlin 
	data=toregress(where=(confirmed>0))
 	list 
 	noitprint 
 	maxiter=32000;
   parms maxpop &popestimate 
   		 rate 1 
   		 maxslo 10;                        
   model confirmed = maxpop / (1 + exp(-rate*(timeperiod - maxslo)));  
   output out=ModelOut predicted=Pred lclm=Lower95 uclm=Upper95;
   estimate 'Dt' log(81) / rate;                   
run;
 
title "Logistic Growth Curve Model of a &region";
proc sgplot data=ModelOut noautolegend;
   band x=Timeperiod lower=Lower95 upper=Upper95;         /* confidence band for mean */
   scatter x=Timeperiod y=confirmed;                         /* raw observations */
   series x=Timeperiod y=Pred;                            /* fitted model curve */
/*    inset ('K' = '261'  'r' = '0.088'  'b' = '34.3') / border opaque; /* parameter estimates */
   xaxis grid; yaxis grid;
run;