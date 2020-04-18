%macro TSimulate(N=N,tau=tau,Rho0=Rho0,sigma=sigma,enddate=&sysdate);

	ods graphics on / reset width=7.5in height=5in imagemap outputfmt=svg;

	PROC TMODEL 
		OUTMODEL=_model; 
		PARAMETERS
			R0		&Rho0
			i0		1
/* 			sigma	&sigma */
		;
		bounds 0.5 <= R0 <= 13;
/* 			   0.1 <= sigma <= 5; */
		control
			N 		= &N
			sigma	= &sigma
			tau		= &tau
		;
			
		gamma 	= 1 / tau;
		beta 	= R0 * gamma / N;
	   
		DERT.S_T = -beta * I_T * S_T ;
		DERT.E_T =  beta * I_T * S_T - sigma * E_T;
		DERT.I_T =                     sigma * E_T - gamma * I_T;
		DERT.R_T =                                   gamma * I_T ;		       
	
		cases = I_T + R_T;
	
		outvars S_T  E_T  I_T  R_T;
	
		fit cases init=(S_T=&N E_T=0 I_T=i0 R_T=0 ) / 
			time		= date 
			dynamic 
			outpredict 
			outactual
	        out			= _outpred
	        covout 
	        outest		= _outcov
	        optimizer	= ormp(opttol=1e-5) 
	        ltebound	= 1e-10 
	        data		= _mdlData;
	RUN;
	QUIT;

	data _null_;
		set _outcov(where=(_name_=""));
		call symputx('r0est', round(R0, 0.01));
		call symputx('i0est', round(i0, 0.01));
		call symputx('endfit', put("&enddate"d, mmddyy.));
	run;

	/*Plot results*/

	title &region Until &endfit;
	title2 "Fit of Cumulative Infections (R0=&r0est i0=&i0est)";

	proc sgplot data=_outpred des="&region In-Sample Prediction";
		where _type_ ne 'RESIDUAL';
		series x=date y=cases / group=_type_ markers legendlabel="Actual/Predict"
								name="Cases" 
								lineattrs=(thickness=3)   
								markerattrs=(symbol=CircleFilled ) 
								tip=(date cases i_T r_t) 
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
		format cases comma10.;
		label cases='Cumulative Incidence';
	run;
	title;footnote;
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
%mend tsimulate;

%macro CreateModelData(database,region_field,region,enddate=&sysdate);
	data _null_; 
		*call symput("enddate",left(put("&enddate"d,8.))); 
		put "NOTE: Building _model dataset ending on &enddate ";
		put "NOTE:    from the &database._trajectories table";
		put "NOTE:    where &region_field=&region";
	run;
	
	data _mdlData;
		set &database._trajectories(rename=(confirmed=cases filedate=date) 
								where=(&region_field="&Region" 
									and cases>0 
									and date <= "&enddate"d))end=eof;
			if eof then call symput('popest',census2010pop);
	run;
	%if &popest=. %then %do;
		%put WARNING: **************************************************************************;	
		%PUT WARNING: POPEST IS MISSING. Please provide a value for N.                     *****;
		%put WARNING: Setting POPEST to default of 10e6. This is likely not what you want. *****;
		%put WARNING: **************************************************************************;
		%let popest=10e6;
	%end;
	%else %do;
		%put NOTE: POPEST is %sysfunc(putn(&popest,comma12.));
	%end;
%mend CreateModelData;


%macro workDelete(tabname);
	proc datasets library=work;
		delete &tabname;
	quit;
%mend workDelete;

%macro thinDS;
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
%mend thinDS;

%macro LookupRegion(table,field,value);

	/* * Look up CBSA or FIPS titles *; */
	proc sql; 
		select distinct &field, combined_key 
			from &table
			where upcase(&field) contains upcase("&value"); 
	quit;
	
%mend LookupRegion;