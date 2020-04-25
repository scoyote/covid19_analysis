

options orientation=landscape papersize=tabloid ;
ods graphics on / reset width=17in height=11in ;

%let gsym		=circlefilled; 
%let gsize		=5;

%let confirmline   =%str( yaxis=y lineattrs=(thickness=2 color=darkblue) );
%let confirmmarker =%str( yaxis=y markerattrs=(symbol=circlefilled size=10 color=darkblue) FILLEDOUTLINEDMARKERS=TRUE MARKERFILLATTRS=(color=darkblue) MARKEROUTLINEATTRS=(color=darkblue) );
%let deathline	   =%str( yaxis=y2 lineattrs=(thickness=2 color=darkred) );
%let deathmarker   =%str( yaxis=y2 markerattrs=(symbol=circlefilled size=10 color=darkorange) FILLEDOUTLINEDMARKERS=TRUE MARKERFILLATTRS=(color=darkorange) MARKEROUTLINEATTRS=(color=darkorange) );
%let deathmarker2  =%str( yaxis=y2 markerattrs=(symbol=circlefilled size=12 color=darkred) FILLEDOUTLINEDMARKERS=TRUE MARKERFILLATTRS=(color=darkred) MARKEROUTLINEATTRS=(color=darkred) );
%let overlayopts   =%str( height=4.5in width=7.5in xaxisopts=(label=" " timeopts=(tickvalueformat=mmddyy5.)) yaxisopts=(label="Confirmed") y2axisopts=(label="Deaths"));
%let xaxisopts     =%str( xaxisopts=(griddisplay=Off gridattrs=(color=BWH ) type=time timeopts=(interval=day tickvaluerotation=diagonal tickvaluefitpolicy=rotatealways splittickvalue=FALSE) ));
%let yaxisopts     =%str( yaxisopts=(griddisplay=ON gridattrs=(color=BWH)));
proc template;
	define statgraph lattice;
	begingraph / designwidth=1632px designheight=960px ;
		entrytitle "SARS-CoV-2 Situation Report for Georgia";
		layout lattice / border=false pad=0 opaque=true rows=2 columns=2 columngutter=0;
			cell; 
				cellheader; entry "  Cumulative Infections and Deaths  ." / textattrs=(size=12); endcellheader;
		      	layout overlay / &overlayopts &yaxisopts;
		      		barchart  category=filedate response=confirmed 	/ stat=sum datatransparency=0.50;
					linechart category=filedate response=deaths 	/ stat=sum &deathline datatransparency=0.50;
		      	endlayout;
		    endcell;
		    
			cell; 
				cellheader; entry "  Cumulative Infections and Deaths  ." / textattrs=(size=12); endcellheader;
		      	layout overlay / &overlayopts &xaxisopts &yaxisopts;
		      		scatterplot	y=confirmed x=filedate / &confirmmarker	datatransparency=0.50;
					seriesplot	y=confirmed x=filedate / &confirmline	datatransparency=0.50;
					scatterplot	y=deaths 	x=filedate / &deathmarker	datatransparency=0.50;
					seriesplot	y=deaths 	x=filedate / &deathline		datatransparency=0.50;
		      	endlayout;						 
		    endcell;
		    
			cell; 
				cellheader; entry "  New Infections and Deaths - Seasonality Is Problematic  ." / textattrs=(size=12); endcellheader;
		      	layout overlay / &overlayopts &yaxisopts;
		      		barchart    category=filedate 	response=dif1_confirmed / stat=sum datatransparency=0.50;
					scatterplot x		=filedate 	y		=dif1_deaths 	/ &deathmarker2 datatransparency=0.50;
				endlayout; 
			endcell;
		    
			cell; 
				cellheader; entry "  New Infections and Deaths - Seasonality Smoothed with Seven Day Moving Average    ." / textattrs=(size=12); endcellheader;
		      	layout overlay / &overlayopts  &yaxisopts;
		      		barchart  category=filedate response=ma7_new_confirmed 	/ stat=sum datatransparency=0.50;
					linechart category=filedate response=ma7_new_deaths 	/ stat=sum &deathline datatransparency=0.50;
		      	endlayout;	
	      	endcell;
		endlayout;
	endgraph;
	end;
run;


proc sgrender data=state_trajectories(where=(province_state="Georgia" and plotseq<=30) )template=lattice;
run;
      
      
      
      
