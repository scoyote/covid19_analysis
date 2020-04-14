/********************************************************************************************/ 
/***** SEIR_GA_ESTIMATION.SAS - Use real world data to estimate epi parameters 			*****/
/********************************************************************************************/ 
%let rc = %sysfunc(dlgcdir("/covid_analysis/SAS_V2/"));
%include "LoadTimeseries.sas";

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
	;
quit;

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
        out=GA_Predicted 
        covout 
        outest=GA_Estimated optimizer=ormp(opttol=1e-5) ltebound=1e-10 
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
