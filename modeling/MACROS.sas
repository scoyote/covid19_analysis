%macro plotregionest(region);
	data _null_;
		set _outcov(where=(_name_=""));
		call symputx('r0est', round(R0, 0.01));
		call symputx('i0est', round(i0, 0.01));
		call symputx('endfit', put(&enddate, mmddyy.));
	run;

	/*Plot results*/
	ods graphics on / reset width=7.5in height=5in imagemap outputfmt=SVG;
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

%mend plotregionest;