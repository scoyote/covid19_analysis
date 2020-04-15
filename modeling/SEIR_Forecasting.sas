/********************************************************************************************/ 
/***** SEIR_GA_ESTIMATION.SAS - Use real world data to estimate epi parameters 			*****/
/********************************************************************************************/ 
/*
%let rc = %sysfunc(dlgcdir("/covid_analysis/SAS_V2/"));
%include "LoadTimeseries.sas";
%include "MACROS.sas";
proc datasets library=work;
	delete    
		GLOBAL_JOINED  
		GLOBAL_STACKED  
		JHU_CROSSWALK
		RECOVERED_GLOBAL_TS
		STATE_TOTALS
		US_AUGMENTED
		US_JOINED
		US_STACKED
	
		GLOBAL_TRAJECTORIES
	;
quit;
*/

proc sql; 
	select distinct cbsa_title, combined_key 
		from fips_trajectories 
		where upcase(cbsa_title) contains "SAN ANTONIO"; 
quit;
/* %let region=Atlanta-Sandy Springs-Alpharetta, GA; */
%let region=San Antonio-New Braunfels, TX;
%let database=cbsa;
%let region_field=cbsa_title;

/* %let region=13057;  *cherokee ga; */
/* %let database=fips; */
/* %let region_field=fips; */


data _mdlData;
	set &database._trajectories(rename=(confirmed=cases filedate=date) 
							where=(&region_field="&Region" 
								and cases>0 
								and date <= &enddate
								)
							) 
							end=eof;
		if eof then call symput('popest',census2010pop);
run;	
%let N		=&popest;
%let tau	=5.1;
%let Rho0	=2.5;
%let sigma	=0.9;
%let enddate='13APR2020'd;


PROC tMODEL 
	OUTMODEL=_model; 
	PARAMETERS
		R0		&Rho0
		i0		1
	;
	bounds 0.5 <= R0 <= 13;
	control
		N 		= &N
		sigma	= &sigma
		tau		= &tau;
		
	gamma 	= 1 / tau;
	beta 	= R0 * gamma / N;
   
	DERT.S_T = -beta * I_T * S_T ;
	DERT.E_T = beta * I_T * S_T - sigma * E_T;
	DERT.I_T = sigma * E_T - gamma * I_T;
	DERT.R_T = gamma * I_T ;		       

	cases = I_T + R_T;

	outvars S_T  E_T  I_T  R_T;

	fit cases init=(S_T=&N I_T=i0 R_T=0 E_T=0) / 
		time		= date 
		dynamic 
		outpredict 
		outactual
        out			= _outpred
        covout 
        outest		= _outcov
        optimizer	= ormp(opttol=1e-5) 
        ltebound	= 1e-10 
        data=_mdlData;
RUN;
QUIT;

/* Plot the in-sample forecast */
%plotstateest(&region);

/***** 	MCOV SCAFFOLD 	*****/
data mccov;
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
data s;
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
   drop lastdate cnt sigma tau _type_ _weight_ jul31;
   set _outpred( where=(_type_='ACTUAL')) end=last;
   output;
   if last then do;
      lastdate=date;
      call symputx('lastdate',lastdate);
      jul31 = '31jul2020'd - lastdate;
      do cnt=1 to jul31;
         date = lastdate + cnt;
         s_t = .;
         e_t = .;
         i_t = .;
         r_t = .;
         cases = .;
         output;
      end;
   end;
run;

proc Tmodel data=_scaffold model=_model;
   solve s_t e_t i_t r_t / 
   simulate 
   time		=date 
   out		=_forecast 
   random	=25 
   seed		=42042
   quasi	=sobol 
   estdata	=mccov 
   sdata	=s;
run;
quit;

proc sort data=_forecast; by _rep_ date; run;

ods graphics / reset width=7in height=5in imagemap imagefmt=svg;	
	footnote "Susceptable and Removed Components on Right Axis";
	proc sgplot data=_forecast des="SEIR Compartment Phase";
		where _rep_=0;
		label date="Date";
		format s_t e_t i_t r_t comma12. date mmddyy5.;
		series x=date y=S_T / name="Susceptable" y2axis lineattrs=(pattern=mediumdash color="orange" thickness=4) transparency=0.5 smoothconnect;
		series x=date y=E_T / name="Exposed" lineattrs=(color="blue" 	thickness=4) transparency=0.5 smoothconnect;
		series x=date y=I_T / name="Infected" lineattrs=(color="red" 	thickness=4) transparency=0.5 smoothconnect;
		series x=date y=R_T / name="Removed" y2axis lineattrs=(pattern=mediumdash color="green" 	thickness=4) transparency=0.5 smoothconnect;
		xaxis interval=day fitpolicy=rotatethin  ;
		yaxis label="Infected and Exposed Compartment Model";
		y2axis label="Susceptable and Removed Compartment Model";
		label s_T="Susceptable" e_t="Exposed" i_t="Infected" R_t="Removed";
	run;
ods graphics / reset;
/*  */
/* proc sql ; */
/* 	select date,s_t,e_t, i_t,r_T, I_T+R_T as total from _forecast where _rep_=0; */
/* quit; */


   
