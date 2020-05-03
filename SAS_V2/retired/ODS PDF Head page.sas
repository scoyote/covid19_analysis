
options nodate nonumber;  

ods escapechar="^";  
title;
footnote;
data _null_;
	filedate=input("&sysdate9",date9.);
	call symput("cvdate",trim(left(put(max(filedate),worddate32.))));
run;
/* Create a data set containing the desired title text */
	/* Create a data set containing the desired title text */
	data test;
		length text $100;
	   text="Coronavirus Report &cvdate"; output;
	run;

/******** PDF ********/
ods pdf file="coverpage.pdf" notoc startpage=no ; 

/* Insert a logo and blank lines (used to move the title text to the center of page) */
footnote1 j=c "Beware of drawing conclusions from this data. Lagged confirmations and deaths are contained.";
footnote2 j=c "Samuel T. Croker";
footnote3 j=c "Data Source: Johns Hopkins University - https://github.com/CSSEGISandData/SARS-CoV-2  Data Updated: &cvdate";

ods pdf text='^S={preimage="coronavirus-image.png"}';
ods pdf text="^20n";

/* Output the title text */
proc report data=test noheader 
     style(report)={rules=none frame=void} 
     style(column)={font_weight=bold font_size=25pt just=c};
run;

/* Output the remainder of the report */
ods pdf startpage=yes;
/* If the footnote should not persist, use a null FOOTNOTE statement */
*footnote;
proc print data=sashelp.cars(obs=45); 
var make model origin cylinders;

run;

ods pdf close;
