/********************************************************************************************/ 
/***** SEIR_GA_ESTIMATION.SAS - Use real world data to estimate epi parameters 			*****/
/********************************************************************************************/ 
ods graphics / reset width=7in height=5in imagemap imagefmt=png;	

%let rc = %sysfunc(dlgcdir("/covid_analysis/SAS_V2/"));
%include "/covid_analysis/modeling/MACROS.sas";
%include "LoadTimeseries.sas";
%thinDS;
%global popest enddate region;
%let popest=.;


/*********************************************************************************************************
*Diagnostic tools - look up regions. ; 
%lookupregion(fips_trajectories,combined_key,michigan);
**********************************************************************************************************/	

/* %CreateModelData(cbsa,cbsa_title,%str(San Antonio-New Braunfels, TX),enddate=14APR2020); */
/* %CreateModelData(fips,fips,13057, enddate=14APR2020); * Cherokee county ga; */
/* %CreateModelData(cbsa,cbsa_title,%str(Atlanta-Sandy Springs-Alpharetta, GA), enddate=16APR2020); */
/* %CreateModelData(state,province_state,Georgia, enddate=14APR2020); */

/**********************************************************************************************************	
Beta	The parameter controlling how often a susceptible-infected contact results in a new exposure.
		beta 	= R0 * gamma / N;
Gamma	The rate an infected recovers and moves into the resistant phase.
		gamma 	= 1 / tau;
Sigma	The rate at which an exposed person becomes infective. (0.9)
Mu		The natural mortality rate (this is unrelated to disease). 
		This models a population of a constant size,
Initial susceptible	The number of susceptible individuals at the beginning of the model run.
Initial exposed	The number of exposed individuals at the beginning of the model run.
Initial infected	The number of infected individuals at the beginning of the model run.
Initial recovered	The number of recovered individuals at the beginning of the model run.
Days	Controls how long the model will run.
**********************************************************************************************************/
/* Georgia */
%tsimulate(N=10214860,tau=5.081846,Rho0=2.5,sigma=0.9);

%tsimulate(N=&popest,tau=5.081846,Rho0=2.5,sigma=0.9);


proc Tmodel data=_scaffold model=_model;
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
	data _forecast; set _forecast;
		p_difeq = I_T + R_T;
	run;
	
	proc sgplot data=_forecast des="SEIR Compartment Phase";
		where _rep_=0 and date between '10apr20'd and '30apr20'd;
		label date="Date";
		format s_t e_t i_t r_t comma12. date mmddyy5.;
		series x=date y=p_difeq / name="Total Cumulative Cases" markers lineattrs=(pattern=mediumdash color="orange" thickness=4) transparency=0.5 smoothconnect;
		series x=date y=E_T / name="Exposed" lineattrs=(color="blue" 	thickness=4) transparency=0.5 smoothconnect;
		series x=date y=I_T / name="Infected" markers lineattrs=(color="red" 	thickness=4) transparency=0.5 smoothconnect;
		series x=date y=R_T / name="Removed" y2axis lineattrs=(pattern=mediumdash color="green" 	thickness=4) transparency=0.5 smoothconnect;
		xaxis interval=day fitpolicy=rotatethin  ;
		yaxis label="Infected and Exposed Compartment Model";
		y2axis label="Susceptable and Removed Compartment Model";
		label s_T="Susceptable" e_t="Exposed" i_t="Infected" R_t="Removed";
	run;
ods graphics / reset;



   
