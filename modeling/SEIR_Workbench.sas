/********************************************************************************************/ 
/***** SEIR_Workbench.SAS - Use real world data to estimate epi parameters 			*****/
/********************************************************************************************/ 
ods graphics / reset width=7in height=5in imagemap imagefmt=png;	

%let rc = %sysfunc(dlgcdir("/covid_analysis/SAS_V2/"));
%include "/covid_analysis/modeling/MACROS.sas";
%include "LoadTimeseries.sas";
%thinDS;
%global popest enddate region;
%let popest=.;
%let rundate=20APR2020;


/*********************************************************************************************************
*Diagnostic tools - look up regions. ; 
%lookupregion(fips_trajectories,cbsa_title,idaho);
proc sql;
	select cbsa_title, filedate, confirmed,  census2010pop from cbsa_trajectories where cbsa_title="&titlestring";
	quit;
**********************************************************************************************************/	
%let titlestring=Atlanta-Sandy Springs-Alpharetta, GA;
%CreateModelData(cbsa,cbsa_title,%str(Atlanta-Sandy Springs-Alpharetta, GA), enddate=&rundate);

/* https://web.stanford.edu/~jhj1/teachingdocs/Jones-Epidemics050308.pdf */

ods graphics on / reset width=7.5in height=5in imagemap outputfmt=svg;
title "&titlestring";
PROC TMODEL 
	OUTMODEL=_model; 
	PARAMETERS
		R0		2.0
		i0		1
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

	cases = I_T + R_T;

	outvars S_T  E_T  I_T  R_T ;

	fit cases init=(S_T=&popest E_T=0 I_T=i0 R_T=0 ) / 
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


/***** Plot results *****/
	
		data _null_;
			set _outcov(where=(_name_=""));
			call symputx('r0est', round(R0, 0.01));
			call symputx('i0est', round(i0, 0.01));
			call symputx('endfit', put("&enddate"d, mmddyy.));
		run;
	
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
	   drop lastdate cnt sigma tau _type_ _weight_ jul31;
	   set _outpred( where=(_type_='ACTUAL')) end=last;
	   output;
	   if last then do;
	      lastdate=date;
	      call symputx('lastdate',lastdate);
	      edate = '31aug2020'd - lastdate;
	      do cnt=1 to edate;
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
	data scaffold;
		merge _scaffold (in=y1)   _outpred(in=y2 where=(_type_='ACTUAL') keep=cases date _type_);
		by date;
		if y1;
		drop _type_ _estype_;
	run;
/***** Forecast over entire period *****/
title "SEIR Forecasting for &titlestring";

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
data _forecast; set _forecast;
	p_difeq = I_T + R_T;
run;
proc sort data=_forecast; by _rep_ date; run;
ods html5 file="/covid_analysis/modeling/graphs/&titlestring._forecast.html" 
		gpath= "/covid_analysis/modeling/graphs/" 
		device=svg 
		options(svg_mode="inline");
ods graphics / reset width=7in height=5in imagemap imagefmt=svg imagename="&titlestring._forecast";	
	title "SEIR Forecast for &titlestring";
	footnote "Susceptable and Removed Components on Right Axis";
	proc sgplot data=_forecast des="SEIR Compartment Phase";
		where _rep_=0;
		label date="Date";
		format s_t e_t i_t r_t comma12. date mmddyy5.;
		series x=date y=S_T 	/ name="Susceptable" lineattrs=(pattern=mediumdash color="orange" 	thickness=4) transparency=0.5 smoothconnect;
		series x=date y=E_T 	/ name="Exposed" 	 lineattrs=(color="blue" 						thickness=4) transparency=0.5 smoothconnect;
		series x=date y=I_T 	/ name="Infected" 	 lineattrs=(color="red"  						thickness=4) transparency=0.5 smoothconnect;
		series x=date y=R_T 	/ name="Removed"  	 lineattrs=(pattern=mediumdash color="green" 	thickness=4) transparency=0.5 smoothconnect;
		series x=date y=p_difeq / name="All Cases"   lineattrs=(pattern=mediumdash color="gray" 	thickness=4) transparency=0.5 smoothconnect;
		xaxis interval=day fitpolicy=rotatethin  ;
		yaxis label="Infected and Exposed Compartment Model";
/* 		y2axis label="Susceptable and Removed Compartment Model"; */
		label s_T="Susceptable" e_t="Exposed" i_t="Infected" R_t="Removed";
	run;

	
	proc sgplot data=_forecast des="SEIR Compartment Phase";
		where _rep_=0 and date between '10apr20'd and '30apr20'd;
		label date="Date";
		format s_t e_t i_t r_t comma12. date mmddyy5.;
		series x=date y=p_difeq / name="Total Cumulative Cases" markers lineattrs=(pattern=mediumdash color="orange" thickness=4) transparency=0.5 smoothconnect;
		series x=date y=E_T / name="Exposed" lineattrs=(color="blue" 	thickness=4) transparency=0.5 smoothconnect;
		series x=date y=I_T / name="Infected" markers lineattrs=(color="red" 	thickness=4) transparency=0.5 smoothconnect;
		series x=date y=R_T / name="Removed" y2axis lineattrs=(pattern=mediumdash color="green" 	thickness=4) transparency=0.5 smoothconnect;
		scatter x=date y=cases;
		xaxis interval=day fitpolicy=rotatethin  ;
		yaxis label="Infected and Exposed Compartment Model";
		y2axis label="Susceptable and Removed Compartment Model";
		label s_T="Susceptable" e_t="Exposed" i_t="Infected" R_t="Removed";
	run;
ods graphics / reset;

ods html5 close;



   
