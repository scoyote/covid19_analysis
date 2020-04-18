data _test;
	a=5; 
	b=0.006;
	c=700;
	do x = -1000 to 1000 by 10;
		do rep=1 to 5;
			y= c/(1+exp(b*x))+rannor(12345);
			output;
		end;
	end;
	drop rep a b c;
run;
proc sgplot;
	scatter x=x y=y;
run;

proc nlin data=_test plots=all;
	parms c=7000a =2 b=-0.005;
	model y= c /(1 + a + exp(-b* x));
run;

data _null_;
	do i=1 to 10;
		a= rannor(13455);
		put a=;
	end;
run;