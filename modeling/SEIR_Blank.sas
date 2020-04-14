
/********************************************************************************************/ 
/***** Methods Adopted from http://www.public.asu.edu/~hnesse/classes/seir.html				*/
/********************************************************************************************/ 
/* %LET BETA					=0.9; 	/* The parameter controlling how often a susceptible-infected contact results in a new exposure. */
/* %LET GAMMA					=0.2;	/* The rate an infected recovers and moves into the resistant phase. */
/* %LET SIGMA					=0.5;	/* The rate at which an exposed person becomes infective */
/* %LET MU						=0;		/* The natural mortality rate (this is unrelated to disease). This models a population of a constant size */
%LET INITIAL_SUSCEPTIBLE	=1000;	/* The number of susceptible individuals at the beginning of the model run.*/
%LET INITIAL_EXPOSED		=1;		/* The number of exposed individuals at the beginning of the model run. */
%LET INITIAL_INFECTED		=1;		/* The number of infected individuals at the beginning of the model run. */
%LET INITIAL_RECOVERED		=0;		/* The number of recovered individuals at the beginning of the model run.*/
%LET DAYS					=30; 	/* Controls how long the model will run*/

/* http://gabgoh.github.io/COVID/ */
DATA D_SCAFFOLD(Label="Initial Conditions of Simulation"); 
	S_T = &INITIAL_SUSCEPTIBLE;	* - (&INITIAL_INFECTED/&BETA) - &GAMMA;
	E_T = &INITIAL_EXPOSED;
	I_T = &INITIAL_INFECTED ;	*/&BETA;
	R_T = &INITIAL_RECOVERED;
	DO TIME = 0 TO &DAYS; 
		OUTPUT; 
	END; 
RUN;

PROC MODEL DATA = D_SCAFFOLD plots=NONE; 
	PARAMETERS
		N 		&INITIAL_SUSCEPTIBLE
		R0		2
		inf		3
		lat		1
	;
	gamma = 1/inf;
	alpha = 1/lat;
	beta = R0 *gamma/N;

	DERT.S_T = -beta * I_T * S_T ;
	DERT.E_T = beta * I_T * S_T - alpha * E_T;
	DERT.I_T = alpha * E_T - gamma * I_T;
	DERT.R_T = gamma * I_T ;		       
	SOLVE S_T  E_T  I_T  R_T / OUT = TMODEL_SEIR; 	
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
