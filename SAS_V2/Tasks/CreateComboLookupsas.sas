/* Step 1: Set up the permanent library and URL fileref to the data */
	libname pCovid '/repositories/covid19_analysis/SAS_V2/data';
	
	proc sql;
		create table pcovid.state_combo as select distinct province_state as state from work.state_trajectories;
		create table pcovid.nation_combo as select distinct location as nation from work.global_trajectories;
		create table pcovid.cbsa_combo as select distinct cbsa_title as cbsa from work.cbsa_trajectories;
	quit;
		