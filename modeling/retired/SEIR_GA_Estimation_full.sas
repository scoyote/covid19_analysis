/********************************************************************************************/ 
/***** SEIR_GA_ESTIMATION.SAS - Use real world data to estimate epi parameters 			*****/
/********************************************************************************************/ 
/*
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
		
		CBSA_TRAJECTORIES 
		FIPS_TRAJECTORIES
		GLOBAL_TRAJECTORIES
	;
quit;
*/

%let N=10000;
%let tau=5.1;
%let Rho0=2.5;
%let sigma=0.2;
%let mu = 0;
%let nu = 0;
%let enddate='12APR2020'd;

PROC MODEL outmodel=_model1; 
	PARAMETERS
		R0		&Rho0
		i0		1
	;
	bounds 0.5 <= R0 <= 13;
	control
		N 		= &N
		sigma	= &sigma
		tau		= &tau;
		
	gamma 	= 0.2;*&gamma;
	beta 	= 0.9 ;*R0 * gamma / N;
	mu 		= &mu;
	nu		= &nu;
   
	DERT.S_T = mu * (N - S_T) -beta * I_T * S_T - nu * S_T;
	DERT.E_T = beta * I_T * S_T - (mu + sigma) * E_T;
	DERT.I_T = sigma * E_T - (mu + gamma) * I_T;
	DERT.R_T = gamma * I_T - mu * R_T + nu * S_T;		       

	cases = I_T + R_T;
	solve S_T E_T I_T R_T / OUT = TMODEL_SEIR;;
	outvars S_T E_T I_T R_T;

	fit cases init=(S_T=&N I_T=i0 R_T=0 E_T=0) / 
		time=date 
		dynamic 
		outpredict 
		outactual
        out=gapred
        covout 
        outest=gaprmcov
        data=state_trajectories(rename=(confirmed=cases filedate=date) where=(Province_State="Georgia" and cases>0 and date <= &enddate))
	
/*         optimizer=ormp(opttol=1e-5) ltebound=1e-10  */
        ;
RUN;
QUIT;


ods graphics / reset width=7in height=5in imagemap;	
	proc sgplot data=gapred(where=(_type_="PREDICT"));
		series x=date y=S_T / lineattrs=(color="orange") smoothconnect;
		series x=date y=E_T / lineattrs=(color="cyan") smoothconnect;
		series x=date y=I_T / lineattrs=(color="red") smoothconnect;
		series x=date y=R_T / lineattrs=(color="green") smoothconnect;
	run;
ods graphics / reset;




%macro plotstateest(state,pre);
   data _null_;
      set &pre.prmcov(where=(_name_=""));
      call symputx('r0est',round(R0,0.01));
      call symputx('i0est',round(i0,0.01));
      call symputx('endfit',put(&enddate,mmddyy.));
   run;
    
   data &pre.pred;
      set &pre.pred;
      label cases='Cumulative Incidence';
   run;
   
   /*Plot results*/
   title &state Until &endfit;
   title2 "Fit of CumulativeInfections (R0=&r0est i0=&i0est)";
   
   proc sgplot data=&pre.pred;
       where _type_  ne 'RESIDUAL';
       series x=date y=cases / lineattrs=(thickness=2) group=_type_  markers name="cases";
       format cases comma10.;
   run;
%mend plotstateest;

%plotstateest(Georgia,ga);



data mccov;
   set gaprmcov;
   if _name_ ^= "" then do;
      R0 = 0;
      i0 = 0;
      di = 0;
      dstd = 0;
      if  _name_ = "di" then di = 300;
   end;
run;

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




data _project;
   drop lastdate cnt sigma tau _type_ _weight_ jul31;
   set gapred( where=(_type_='ACTUAL')) end=last;
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

proc model data=_project model=_model;
   solve s_t e_t i_t r_t / 
   simulate 
   time=date 
   out=_forecast 
   random=25 
   seed=1 
   quasi=sobol 
   estdata=mccov 
   sdata=s;
quit;

proc sort data=_forecast; by date; run;

ods graphics / reset width=7in height=5in imagemap;	
	proc sgplot data=_forecast;
		series x=date y=S_T / lineattrs=(color="orange") smoothconnect;
		series x=date y=E_T / lineattrs=(color="cyan") smoothconnect;
		series x=date y=I_T / lineattrs=(color="red") smoothconnect;
		series x=date y=R_T / lineattrs=(color="green") smoothconnect;
	run;
ods graphics / reset;


/*  */
/*  */
/* data gaforevar; */
/*    set _forecast; */
/*    if date >= &lastdate then do; */
/*       ifore=i_t; */
/*       if date > &lastdate then i=.; */
/*    end; */
/*    if _rep_ ^= 0 then i_t = .; */
/*  */
/* run; */
/*  */
/* %macro plotsim(state,pre); */
/*    title &state Forecast; */
/*     */
/*    proc sgplot data=&pre.forevar noautolegend; */
/*        series x=date y=i_t / lineattrs=(thickness=3) name="modeled"; */
/*        series x=date y=ifore /  group=_rep_ lineattrs=(pattern=solid thickness=1) name="forecast"; */
/*        yaxis min=0; */
/*        format i ifore comma10.; */
/*    run; */
/*    proc sgplot data=&pre.forevar noautolegend; */
/*        series x=date y=i_t / lineattrs=(thickness=3) name="modeled"; */
/*        series x=date y=ifore /  group=_rep_ lineattrs=(pattern=solid thickness=1) name="forecast"; */
/*        yaxis min=0 max=30000; */
/*        format i ifore comma10.; */
/*    run; */
/* %mend plotsim; */
/*  */
/* %plotsim(Georgia,ga); */
/*     */
