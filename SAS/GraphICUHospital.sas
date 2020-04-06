*********************************************************************
***** GraphICUHospital.sas - Look at counties - very imperfect	*****
*****						small regions.						*****
*****															*****
***** 															*****
*********************************************************************;



proc sql;
	create table MSA_ICU_summary as	
		select 
			CSA_Title_Augmented
			,sum(confirmed) as confirmed
			,log(sum(confirmed)) as log_confirmed
			,sum(deaths) as deaths
			,log(sum(deaths)) as log_deaths
			,sum(recovered) as recovered
			,sum(total_county_hospitals) as MSA_hospitals
			,sum(total_county_icu_beds) as MSA_ICU_BEDS
			,log(sum(total_county_icu_beds)) as log_msa_icu_beds
			,sum(confirmed)/sum(total_county_hospitals) as confirmed_per_hospital
			,sum(confirmed)/sum(total_county_icu_beds) as confirmed_per_ICU_BED
		from work.JHU_CORE_LOC_MSA_ICU msa
		where confirmed > 0
		group by csa_title_augmented
		order by csa_title_augmented
		;
quit;


proc rank data=msa_ICU_summary out=MSA_Ranks groups=5 ties=dense;                               
	var confirmed 
		deaths 
		msa_hospitals 
		msa_icu_beds
		confirmed_per_hospital
		confirmed_per_icu_bed;                                                          
	ranks confirmed_rank
		deaths_rank 
		msa_hospitals_rank 
		msa_icu_beds_rank
		confirmed_per_hospital_rank
		confirmed_per_icu_bed_rank;                                                      
run;

proc reg data=MSA_RANKS(where=(confirmed_rank>0 and confirmed>0 and msa_icu_beds>0));
	model log_confirmed=log_msa_icu_beds / alpha=.2 ;
	output out=MSA_regvals 
		predicted=p_log_confirmed 
		lcl=lcl_log_confirmed 
		ucl=ucl_log_confirmed  
		lclm=lclm_log_confirmed 
		uclm=uclm_log_confirmed
		;
run;

data MSA_regvals; set MSA_regvals;
	p_confirmed=exp(p_log_confirmed);
	ucl_confirmed=exp(ucl_log_confirmed);
	lcl_confirmed=exp(lcl_log_confirmed);
	uclm_confirmed=exp(uclm_log_confirmed);
	lclm_confirmed=exp(lclm_log_confirmed);
	label p_confirmed="Confirmed Prediction"
		  ucl_confirmed="Confirmed Prediction UCL"
		  lcl_confirmed="Confirmed Prediction LCL"
		  uclm_confirmed="Confirmed UCL"
		  lclm_confirmed="Confirmed LCL";
	if confirmed <= ucl_confirmed - (ucl_confirmed*0.25)
		and confirmed > lcl_confirmed 
		then delete;
	label CSA_TITLE_AUGUMENTED="CBSA";
run;

/*
proc sql;
select confirmed_per_icu_bed_rank,count(*) as freq from msa_regvals group by confirmed_per_icu_bed_rank order by confirmed_per_icu_bed_rank;
quit;
*/

data msa_regvals;
	set msa_regvals;
	if msa_icu_beds>0 then confirmed_ICU_ratio=confirmed/msa_icu_beds;
	label Confirmed_icu_ratio = "Ratio of Confirmed:ICU Beds";
run;
proc sort data=msa_regvals; by msa_icu_beds; run;

options orientation=landscape papersize=(24in 24in) ;
ods graphics / reset width=23.5in height=23.5in imagemap outputfmt=svg;
ods html close;ods rtf close;ods pdf close;ods document close; 
ods html5 
	body="&outputpath./percapita/MSA_ICU_BEDS.html" 
	gpath= "&outputpath/percapita/" 
	device=svg 
	options(svg_mode="inline");
	
	proc sgplot data=MSA_regvals(where=(confirmed_rank>0 and confirmed>0 and msa_icu_beds>0));
		label confirmed="Confirmed"
			  deaths_rank ="Deaths Rank"
			  msa_icu_beds="Number of ICU Beds in CBSA/Area"
		;
		bubble x=MSA_ICU_BEDS
			   y=confirmed
			   size=deaths_rank/
			datalabel=csa_title_augmented 
			datalabelpos=center 
			datalabelattrs=(size=6 ) 
			fillattrs=(transparency=0.75) 
			datalabelpos=center 
			datalabelattrs=(size=6 ) 
			bradiusmin=5 
			bradiusmax=20
			tip =(csa_title_augmented confirmed deaths msa_icu_beds confirmed_icu_ratio)
			tiplabel=('CSBA:' 'Confirmed:' "Deaths:" "ICU Beds" "Case per ICU Bed:")
			tipformat =($25. best12. best12. best12. best12.3);
		series y=p_confirmed x=msa_icu_beds  	/ lineattrs=(color='green') ;
		series y=lcl_confirmed x=msa_icu_beds  	/ lineattrs=(color='orange') ;
		series y=ucl_confirmed x=msa_icu_beds  	/ lineattrs=(color='orange') ;
		xaxis grid type=log values=(2 5 10 50 100 250 500  1000   10000);
		yaxis grid type=log values=(5 10 100 1000 100000 100000);
	run;
ods html5 close;
ods graphics / reset;


/*
proc print data=msa_regvals;
	var csa_title_augmented msa_icu_beds confirmed p_confirmed lcl_confirmed ucl_confirmed;
run;
*/
proc delete data=
	MSA_ICU_summary
	msa_ranks
	msa_regvals
	;
run;
	
	
	
