/********************************************************************/
/***** Plot a single state group - just change the macvar here 	*****/
/********************************************************************/
%let plot_state=Canada;
options orientation=landscape papersize=(7.5in 5in) ;
ods graphics on /  width=7.5in height=5in  imagemap outputfmt=svg ;
ods html5 close; ods html close; ODS Listing close;
ODS HTML5 gpath="&outputpath/graphs"(URL='graphs/') 
		 path="&outputpath"(URL=NONE)
		 file="&plot_state..html"
		 device=svg options(svg_mode="inline");
	%plotstate(state=&plot_state,level=global);
ods html5 close;