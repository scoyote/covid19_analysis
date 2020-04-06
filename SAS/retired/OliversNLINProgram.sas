data weeds; 
  input tx rate y; 
  rate = rate * 1.12; /* convert from lbs/acre to kg/ha */ 
  if rate < 1E-6 then rate = 1E-6; 
  datalines; 
   1        0.000           99 
   1        0.020           84 
   1        0.040           95 
   1        0.080           84 
   1        0.160           53 
   1        0.320            6 
   1        0.641            6 
   1        0.000          103 
   1        0.020           84 
   1        0.040           94 
   1        0.080           79 
   1        0.160           75 
   1        0.320           27 
   1        0.641            7 
   1        0.000          113 
   1        0.020           91 
   1        0.040           80 
   1        0.080           76 
   1        0.160           52 
   1        0.320            6 
   1        0.641            6 
   1        0.000           86 
   1        0.020           78 
   1        0.040           85 
   1        0.080           80 
   1        0.160           53 
   1        0.320           30 
   1        0.641            8 
   1        0.000          110 
   1        0.020          104 
   1        0.040           89 
   1        0.080           84 
   1        0.160           44 
   1        0.320           17 
   1        0.641            9 
   1        0.000           94 
   1        0.020          103 
   1        0.040           97 
   1        0.080           85 
   1        0.160           58 
   1        0.320           17 
   1        0.641            7 
   1        0.000           95 
   1        0.020          113 
   1        0.040           85 
   1        0.080           79 
   1        0.160           33 
   1        0.320           19 
   1        0.641            4 
   1        0.000          101 
   1        0.020          107 
   1        0.040          105 
   1        0.080           87 
   1        0.160           75 
   1        0.320           20 
   1        0.641           11 
; 
run; 

/* proc nlin data=weeds;  */
/*   parameters  alpha=100 delta=4 beta=2.0 gamma=0.2;  */
/*   model y   = delta + (alpha-delta)  / (1 + exp(beta*log(rate/gamma)));  */
/* run;  */
/*  */
/* proc nlin data=weeds; */
/*   parameters  alpha=100 delta=4 */
/*               beta=1 to 2 by 0.5 */
/*               gamma=0.1 to 0.4 by 0.1; */
/*   model y   = delta + (alpha-delta)  / (1 + exp(beta*log(rate/gamma))); */
/* run;  */
/*  */
/* proc nlin data=weeds;   parameters  alpha=100 delta=4 beta=2.0 gamma=0.2;   term = 1 + exp(beta*log(rate/gamma));   model y = delta + (alpha-delta)  / term; run; */
/*  */
/*  */
/* proc nlin data=weeds;   parameters  delta=4 beta=2.0 gamma=0.2;   alpha = 100;   term = 1 + exp(beta*log(rate/gamma));   model y = delta + (alpha-delta)  / term; run; */

proc nlin data=weeds method=newton;   
	parameters  alpha=100 delta=4 beta=2.0 gamma=0.2;   
	term = 1 + exp(beta*log(rate/gamma));   
	model y   = delta + (alpha-delta)  / term;   
	output out=nlinout predicted=pred l95m=l95mean u95m=u95mean l95=l95ind u95=u95ind; 

run; proc print data=nlinout; run;

data filler;   
	do rate = 0.05 to 0.8 by 0.05;     
		predict=1;     
		output;   
	end; 
run;

data fitthis; set weeds filler; run;

proc nlin data=fitthis method=newton;   
	parameters  alpha=100 delta=4 beta=2.0 gamma=0.2;   
	term = 1 + exp(beta*log(rate/gamma));   
	model y   = delta + (alpha-delta)  / term;   
	output out=nlinout predicted=pred;
run; 

proc print data=nlinout(where=(predict=1)); run;




