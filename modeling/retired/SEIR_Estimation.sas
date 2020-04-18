/********************************************************************************************/ 
/***** SEIR_ESTIMATION.SAS - Use real world data to estimate epidemiological parameters *****/
/********************************************************************************************/ 
%let rc = %sysfunc(dlgcdir("/covid_analysis/SAS_V2/"));
%include "LoadTimeseries.sas";

%LET INITIAL_SUSCEPTIBLE	=1000;	/* The number of susceptible individuals at the beginning of the model run.*/
%LET INITIAL_EXPOSED		=1;		/* The number of exposed individuals at the beginning of the model run. */
%LET INITIAL_INFECTED		=1;		/* The number of infected individuals at the beginning of the model run. */
%LET INITIAL_RECOVERED		=0;		/* The number of recovered individuals at the beginning of the model run.*/
%LET DAYS					=30; 	/* Controls how long the model will run*/

DATA D_SCAFFOLD(Label="Initial Conditions of Simulation");
	set state_trajectories(where=(province_state="Georgia" and confirmed > 0) keep=province_state filedate confirmed deaths dif1_confirmed dif1_deaths) end=eof ;
	S_T = &INITIAL_SUSCEPTIBLE;
	E_T = &INITIAL_EXPOSED;
	I_T = &INITIAL_INFECTED ;
	R_T = &INITIAL_RECOVERED;
	TIME = _N_;
	if eof then do;
		call symput("max_time",time);
		call symput("max_date",filedate);
	end;
RUN;

%let N=10e6;
%let tau=5.1;
%let Rho0=2.5;
%let sigma=0.9;
%let enddate='12APR2020'd;

PROC TMODEL outmodel=_model; 
	PARAMETERS
		R0		2
		i0		2
	;
	bounds 0.5 <= R0 <= 13;
	control
		N 		= 100000
		sigma	= &sigma
		tau		= &tau;
		
	gamma 	= 1 / tau;
	beta 	= R0 * gamma / N;
	
	DERT.S_T = -beta * I_T * S_T ;
	DERT.E_T = beta * I_T * S_T - sigma * E_T;
	DERT.I_T = sigma * E_T - gamma * I_T;
	DERT.R_T = gamma * I_T ;		       

	cases = I_T + R_T;

	outvars S_T E_T I_T R_T;

	fit cases init=(S_T=&N I_T=i0 R_T=0 E_T=0) / 
		time=date 
		dynamic 
		outpredict 
		outactual
        out=GApred 
        covout 
        outest=ncprmcov optimizer=ormp(opttol=1e-5) ltebound=1e-10 
        data=state_trajectories(rename=(confirmed=cases filedate=date) where=(Province_State="Georgia" and cases>0 and date <= &enddate));
RUN;
QUIT;


ods graphics / reset width=7in height=5in imagemap;	
	proc sgplot data=TMODEL_SEIR;
		series x=time y=S_T / lineattrs=(color="orange") smoothconnect;
		series x=time y=E_T / lineattrs=(color="cyan") smoothconnect;
		series x=time y=I_T / lineattrs=(color="red") smoothconnect;
		series x=time y=R_T / lineattrs=(color="green") smoothconnect;
	run;
ods graphics / reset;
