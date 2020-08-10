%let codepath=/repositories/covid19_analysis/SAS_V2/Demonstration;
%let rc = %sysfunc(dlgcdir("&codepath")); 
%include 'MACROS.sas';

libname pCovid '/repositories/covid19_analysis/SAS_V2/data';
proc datasets lib=pcovid;
	delete gl_confirmed
			gl_daily
			gl_deaths
			us_confirmed
			us_daily
			us_deaths;
quit;
%GetandBuildJHU_Covid(US,confirmed);
%GetandBuildJHU_Covid(US,deaths);
%GetandBuildJHU_Covid(GL,confirmed);
%GetandBuildJHU_Covid(GL,deaths);

%assembleCovidData(US);
%assembleCovidData(GL);
