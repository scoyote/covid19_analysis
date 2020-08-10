/********************************************************************************************/ 
/***** SEIR_Workbench.SAS - Use real world data to estimate epi parameters 			*****/
/********************************************************************************************/ 
ods graphics / reset width=7in height=5in imagemap imagefmt=svg;	
%let rc = %sysfunc(dlgcdir("/covid_analysis/SAS_V2/"));

/* proc datasets library=work kill; quit; */
/* %include "/covid_analysis/modeling/MACROS.sas"; */
/* %include "LoadTimeseries.sas"; */
/* %thinDS; */

%global popest enddate region;
%let popest=.;
%let startdate=01feb20;
%let rundate=12jul020;
%let back=7;
%let lead=14;

/*********************************************************************************************************
*Diagnostic tools - look up regions. ; 
%lookupregion(fips_trajectories,cbsa_title,idaho);
proc sql;
	select cbsa_title, filedate, confirmed,  census2010pop from cbsa_trajectories where cbsa_title="&titlestring";
	quit;
**********************************************************************************************************/	
/*
48029 - bexar, tx

13057 - cherokee, ga

45019 - charleston
45007 - anderson
45045 - greenville
*/

%CreateModelData(FIPS,FIPS,%str(13057),startdate=01feb20,enddate=&rundate,back=&back);

/* https://web.stanford.edu/~jhj1/teachingdocs/Jones-Epidemics050308.pdf */

proc sql noprint; 
	select distinct combined_key into :titlestring from _mdldata; 
	select distinct left(compress(prxchange('s/["'')(,]+/ /',-1, combined_key))) into :filepart from _mdldata; 
quit;
%let filepart=%cmpres(&filepart);
%put NOTE: filepart=["&filepart"];
data _null_ ;call symput("wordDte",trim(left(put("&sysdate9"d, worddatx32.)))); run;
%put NOTE: Sanity Check: County = &titlestring;


options orientation=landscape papersize=letter  nomprint nomlogic;
ods graphics / reset=all width=10in height=7in imagemap  outputfmt=svg imagefmt=svg;

ods html5 body="SEIRModel_&filepart..htm"  options(svg_mode="inline" bitmap_mode='inline');

title "SARS-CoV-2: SEIR Estimation";
title2 &titlestring;
footnote1  j=c h=1 "Beware of drawing conclusions from this data beyond the purpose for which it was generated.";
footnote2 j=c h=.95 "Data Source: Johns Hopkins University - https://github.com/CSSEGISandData/COVID-19 Data Updated: &sysdate";
footnote3 j=r h=0.5  "Samuel T. Croker - &sysdate9";

PROC TMODEL  
	OUTMODEL=_model; 
	PARAMETERS
		R0		1.1
		i0		20
	;
	bounds 0.5 <= R0 <= 13;
	
	control
		N 		= &Popest
		sigma	= 0.9
		tau		= 5.1
	;

	gamma 	= 1 / tau;
	beta 	= R0 * gamma / N;
   
	DERT.S_T = -beta * I_T * S_T ;
	DERT.E_T =  beta * I_T * S_T - sigma * E_T;
	DERT.I_T =                     sigma * E_T - gamma * I_T;
	DERT.R_T =                                   gamma * I_T ;		       

	cumulative_cases = I_T + R_T;

	outvars S_T  E_T  I_T  R_T ;

	fit cumulative_cases init=(S_T=&popest E_T=0 I_T=i0 R_T=0 ) / 
		time		= date 
		dynamic 
		outpredict 
		outactual
        out			= _outpred
        covout 
        outest		= _outcov
        optimizer	= ormp(opttol=1e-5) 
        ltebound	= 1e-10 
        data		= _mdlData(where=(role='I'));
	RUN;
QUIT;


/* Set some macro variables from the covariance output data set. */
data _null_;
	set _outcov(where=(_name_=""));
	call symputx('r0est', round(R0, 0.01));
	call symputx('i0est', round(i0, 0.01));
	call symputx('endfit', put("&rundate"d, worddate32.));
run;


/***** Plot results *****/
title "SARS-CoV-2: SEIR Estimation";
title2 &titlestring;
title3 "Fit of Cumulative Infections (R0=&r0est i0=&i0est) - Updated &wordDte";

		proc sgplot data=_outpred des="&region In-Sample Prediction";
			where _type_ ne 'RESIDUAL';
			series x=date y=cumulative_cases / group=_type_ markers legendlabel="Actual/Predict"
									name="Cases" 
									lineattrs=(thickness=3)   
									markerattrs=(symbol=CircleFilled ) 
									tip=(date cumulative_cases i_T r_t) 
									tipformat=(mmddyy5. comma12.);
			series x=date y=i_t / group=_type_ markers  legendlabel="Infected SEIR"
									name="I" 
									transparency=0.5
									lineattrs=(thickness=3 color='vlipb') 
									markerattrs=(color='vlipb' symbol=CircleFilled );
			series x=date y=r_t / group=_type_ markers  legendlabel="Removed SEIR"
									name="R" 
									transparency=0.5
									lineattrs=(thickness=3 color='bibg') 
									markerattrs=(color='bibg' symbol=CircleFilled );
			format cumulative_cases comma10.;
			label cumulative_cases='Cumulative Incidence';
		run;

/***** END Plot results *****/
	

/***** 	MCOV SCAFFOLD 	*****/
	data _mccov;
	   set _outcov;
	   if _name_ ^= "" then do;
	      R0 = 0;
	      i0 = 0;
	      di = 0;
	      dstd = 0;
	      if  _name_ = "di" then di = 300;
	   end;
	run;
	
/***** 	S SCAFFOLD 	*****/
	data _s;
	   keep _name_ s_t e_t i_t r_t;
	   array endovar[4] s_t e_t i_t r_t;
	   array endonam[4] $ ( "s_t" "e_t" "i_t" "r_t");
	   cov = 0;
	   output;
	   case = 0;
	   do i = 1 to dim(endovar);
	      _name_ = endonam[i];
	      do j = 1 to dim(endovar);
	         if i=j then endovar[j] = cov;
	         else endovar[j] = 0;
	      end;
	      output;
	   end;
	run;
	
	
	/***** Prep the data from the initial estimation 	*****/
	/***** Add date scaffold for the forecasting part	*****/
	data _scaffold;
	   drop lastdate cnt sigma tau _type_ _weight_ ;
	   set _outpred( where=(_type_='ACTUAL')) end=last;
	   output;
	   if last then do;
	      lastdate=date;
	      call symputx('lastdate',lastdate);
	      edate = '31oct2020'd - lastdate;
	      do cnt=1 to edate;
	         date = lastdate + cnt;
	         s_t = .;
	         e_t = .;
	         i_t = .;
	         r_t = .;
	         cumulative_cases = .;
	         output;
	      end;
	   end;
	run;
	data scaffold;
		merge _scaffold (in=y1)   _outpred(in=y2 where=(_type_='ACTUAL') keep=cumulative_cases date _type_);
		by date;
		if y1;
		drop _type_ _estype_;
	run;
/***** Forecast over entire period *****/

proc Tmodel data=scaffold model=_model;
   solve s_t e_t i_t r_t / 
   simulate 
   time		= date 
   out		= _forecast 
   random	= 25 
   seed		= 42042
   quasi	= sobol 
   estdata	= _mccov 
   sdata	= _s;
run;
quit;
proc sort data=_forecast; by date _type_; run;
data _graph; 
	merge _mdldata(in=b keep=role date cases  cumulative_cases deaths cumulative_deaths rename=(cumulative_cases=actual_cumulative_cases))
		  _forecast(in=a);
	by date;
	if a;
	p_difeq = I_T + R_T;
	if missing(role) then role='E';
run;


 title "SARS-CoV-2: SEIR Estimation";
title2 &titlestring;
title3 "Fit of Cumulative Infections (R0=&r0est i0=&i0est) - Updated &wordDte";


proc sort data=_graph; by _rep_ date; run;

data _cmap;
	informat id $20. value $1. linecolor symbol $30. color $50.;
	ID='rolecol';value = 'I'; color	= 'green' ; size=5; symbol='circle'; markercolor=color;  linecolor=color; fillcolor=color; output;
	ID='rolecol';value = 'O'; color	= 'blue'; size=15; symbol='triangle';markercolor=color; linecolor=color; fillcolor=color; output;
	ID='rolecol';value = 'E'; color	= 'BWH';  symbol='square'; linecolor=color;markercolor=color; fillcolor=color; output;
run;

ods graphics /reset=all;
	proc sgplot data=_graph des="SEIR Short Term Forecast" dattrmap=_cmap ;
		where _rep_=0;
		label date="Date";
		series x=date y=p_difeq 				/ name="Predicted Cases" lineattrs=(pattern=solid color=darkred thickness=4) transparency=0.5 smoothconnect;
		series x=date y=actual_cumulative_cases / group=role groupmc=role markerattrs=(symbol=circlefilled) transparency=.5 name="Actual Cases" markers attrid=rolecol lineattrs=(thickness=0);
		xaxis interval=day  ;
		yaxis label="Infected and Exposed Compartment Model";
		where date between '21jun20'd and '20jul20'd;
	run;

	
	proc sgplot data=_graph des="SEIR Compartment Phase";
		where _rep_=0 and date between '01jul20'd and '31aug20'd;
		label date="Date";
		format s_t e_t i_t r_t comma12. date mmddyy5.;
		series x=date y=p_difeq / name="Total Cumulative Cases" lineattrs=(pattern=mediumdash color="orange" thickness=4) transparency=0.5 smoothconnect;
		series x=date y=E_T / name="Exposed" lineattrs=(color="blue" 	thickness=4) transparency=0.5 smoothconnect;
		series x=date y=I_T / name="Infected" markers lineattrs=(color="red" 	thickness=4) transparency=0.5 smoothconnect;
		series x=date y=R_T / name="Removed" y2axis lineattrs=(pattern=mediumdash color="green" 	thickness=4) transparency=0.5 smoothconnect;
		scatter x=date y=cumulative_cases;
		xaxis interval=day fitpolicy=rotatethin  ;
		yaxis label="Infected and Exposed Compartment Model";
		y2axis label="Susceptable and Removed Compartment Model";
		label s_T="Susceptable" e_t="Exposed" i_t="Infected" R_t="Removed";
	run;
ods graphics / reset;

ods html5 close;

proc datasets lib=work;
	delete 
/* 		_forecast  */
		_mccov  
/* 		_mdldata  */
		_model 
		_outcov 
/* 		_outpred  */
		_s 
		_scaffold 
		colormap 
		daycolormap 
		scaffold
	;
quit;


   
