/*--------------------------------------------------------------

                    SAS Sample Library

        Name: tmogs.sas
 Description: Example program from SAS/ETS User's Guide,
              The TMODEL Procedure
       Title: Getting Started Example for PROC TMODEL
     Product: SAS/ETS Software
        Keys: nonlinear simultaneous equation models
        PROC: TMODEL
       Notes:
		 URL: https://documentation.sas.com/?docsetId=etsug&docsetTarget=etsug_code_tmogs.htm&docsetVersion=15.1&locale=en
--------------------------------------------------------------*/


data soln;
   keep exprun t x y;
   length exprun $ 8;
   array experno[4] $ _temporary_ ( "one" "two" "three" "four" );
   call streaminit (1);
   do i = 1 to 4;
      exprun = experno[i];
      do t = 0 to 5 by 0.1;
         /* analytic solution for the ODE system */
         x = 1/2*(exp(-3*t) - exp(-t)) + rand('normal',0,0.01);
         y = 1/2*(exp(-3*t) + exp(-t)) + rand('normal',0,0.01);
         output;
      end;
   end;
run;

proc model outmodel=ode plots=all;
   endo x y;
   parms a b;
   g = exp (x + y);
   dert.x = -a*x - log (g);
   dert.y = -b*y - log (g);
quit;

proc model data=soln model=ode;
   fit / time=t dynamic;
quit;

proc tmodel data=soln model=ode;
   crosssection exprun;
   fit / time=t dynamic;
quit;

data d;
   length cs $ 8;
   array csname{5} $ _temporary_ ( 'first' 'second' 'third' 'fourth' 'fifth' );
   call streaminit (1);
   do pp = 1 to dim(csname);
      lagx = 0;
      do t = 1 to 10;
         x = 0.8*lagx + rand('normal');
         lagx = x;
         cs = csname[pp];
         output;
      end;
   end;
run;

proc tmodel data=d;
   endo x;
   crosssection cs;
   parms p;

   x = p*lag(x);
   fit;
quit;