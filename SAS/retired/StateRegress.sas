
/* %let region=Nation:India; */
%let region=Florida-US;
%let alpha=0.2;
%let pvar=Deaths;
%let mpop=100000;
%let rate=0.5;
%let mid=10;

proc sql noprint;
	create table PreppedForNLIN as
	select *
	,monotonic() as timeperiod
	,monotonic() as idvar 
	from
	(select 
		 filedate
		,location
		,sum(confirmed) as confirmed
		,sum(deaths) as deaths
		from JHU_CORE_TS
		where location like "&region"
		group by filedate,location
	)	order by filedate,location
	;
	proc sql noprint; select max(timeperiod), max(filedate) into :maxtime,:maxdate from PreppedForNLIN;
quit;

%put NOTE: We found for &region that the last filedate was &maxdate and the last timeperiod was &maxtime;

/* Run nonlinear curve fitting - save the model out for forecasting */
%let alphalab=%sysevalf(100*(1-&alpha)); %put [&alphalab]; 
/* ods output ParameterEstimates=PE; /* Save the estimates in a dataset to draw in later */
/* proc nlin */
/* 	data=PreppedForNLIN(where=(confirmed>0))  */
/* 		method=marquardt list noitprint maxiter=32000 alpha=&alpha; */
/*    parms maxpop 1000000  */
/*    		 rate 	0.5  */
/*    		 mid 	25;                         */
/*    model confirmed = maxpop / (1 + exp(-rate*(timeperiod - mid)))  ;   */
/*    output out=Model_nlin  */
/*    			predicted=Predicted_Known */
/*    			lcl=Lower&alphalab.Confidence  */
/*    			ucl=Upper&alphalab.Confidence  */
/*    			lclm=Lower&alphalab.Predict  */
/*    			uclm=Upper&alphalab.Predict  */
/*    		/der ;                    */
/* run; */

/***********************************************************************************/
/* https://stats.idre.ucla.edu/sas/library/sas-librarynonlinear-regression-in-sas/ */
/***********************************************************************************/
data addblank;
	x = put(&maxdate,yymmdd10.);
	format filedate yymmdd10.;
	do tx = 1 to 100 by 5;
		timeperiod = &maxtime+tx;
		filedate=intnx('day',&maxdate,tx); /* add datetime to the timeperiod*/
		predict=1; /*set the flag if a prediction*/
		output;
	end;
	drop tx;
run;
data scoringds;
	set PreppedForNLIN
		addblank;
	keep location timeperiod filedate confirmed deaths;
run;

ods table ParameterEstimates=PE;
proc nlin
   data=scoringds method=marquardt list noitprint maxiter=32000;
   parms maxpop &mpop rate &rate mid &mid;                        
   model &pvar = maxpop / (1 + exp(-rate*(timeperiod - mid)))  ;  
   output out=ScoreOut predicted=Predicted
   			lcl=Lower&alphalab.Confidence 
   			ucl=Upper&alphalab.Confidence 
   			lclm=Lower&alphalab.Predict 
   			uclm=Upper&alphalab.Predict 
   ;
run;
/* load the parameter estimates into macro variables */
data _null_; set pe;
	call symput(parameter,estimate);
run;
run;%put &maxpop &rate &mid;

proc sort data=scoreout; by timeperiod; run;
options orientation=landscape papersize=(8in 5in) ;
ods graphics on / reset width=8in height=5in imagemap outputfmt=svg;
ods html close;ods rtf close;ods pdf close;ods document close; 
ods html5 file="&outputpath./predictions/&region..html" gpath= "&outputpath/states/" device=svg options(svg_mode="inline");
	footnote 'Data Source: Johns Hopkins University - https://github.com/CSSEGISandData/COVID-19';	
	title "Logistic Growth Curve Model for &pvar of &region";
	footnote2 "Prediction Made from Data as of %sysfunc(putn(&maxdate,yymmdd10.))";
	
	proc sgplot data=scoreout noautolegend;
	   band x=filedate 
	   		lower=Lower&alphalab.Predict    
	   		upper=Upper&alphalab.Predict   / 
	   			fillattrs=(color='CX8789d4' transparency=0.85);   
	   scatter x=filedate y=&pvar /
			markerattrs=(color='blue' )
			tip		=(filedate &pvar deaths predicted timeperiod)
			tiplabel=("Date" "&pvar" "Deaths" "Prediction" "Forecast" "Time Period")
			tipformat=(yymmdd10. comma10. comma10. comma10.2 comma10.2 comma10.);                            
	   series x=filedate y=Predicted 	/ lineattrs=(color='red') ; 
	   xaxis grid; 
	   yaxis grid;
	run;
	
ods html5 close;
ods graphics / reset;

proc delete data= scoringds
	addblank
	scoreout
	pe
	PreppedForNLIN;
quit;


/* Sanity Checks ***************************************;

proc sort data=plotdataset; by filedate; run;
proc print data=plotdataset;
	var timeperiod filedate dt_ftp confirmed pred pred2;
run;

*/



