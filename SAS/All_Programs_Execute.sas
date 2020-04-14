/* clean up from previous runs if necessary */
proc datasets library=WORK kill; run; quit;
%global adjust_note	adjust_date adjust_confirmed adjust_deaths;

%let covidpath=/covid19data/csse_covid_19_data/csse_covid_19_daily_reports;
%let progpath=/covid_analysis/sas;
%let outputpath=/covid_analysis/graphs/;


%put NOTE: ***********************;
%put NOTE: UPDATING GIT REPOSITORY;
%put NOTE: ***********************;

/* https://go.documentation.sas.com/?docsetId=lefunctionsref&docsetTarget=n1mlc3f9w9zh9fn13qswiq6hrta0.htm&docsetVersion=9.4&locale=en */
data _null_;
    rc= GITFN_PULL("/covid19data");
    put "NOTE: GIT " rc=;
run;
%put NOTE: ***********************;
%put NOTE: END UPDATING GIT REPO;
%put NOTE: ***********************;

libname covid '/covid19data';   
libname fips "/covid_analysis/data";        
filename covid19 "&covidpath";

/* load macros */
%include "&progpath./MACROS.sas";
%include "&progpath./HardLoadData.sas";
%include "&progpath./ImportMSACBSA.sas";
%include "&progpath./LoadICUBeds.sas";
%include "&progpath./GenerateSummaryTables.sas";

proc sql;
	select location,province_state,country_region
	,filedate
		,count(*) as observations
		,sum(confirmed) as total_confirmed
		,sum(deaths) as total_deaths
	from WORK.JHU_CORE_TS
	where location="Georgia-US"
	group by location,province_state,country_region
	,filedate
	order by 
	filedate,
	country_region,province_state,location;
quit;

%include "&progpath./GraphTrajectories.sas";
%include "&progpath./GraphPerCapita.sas";
%include "&progpath./GraphICUHospital.sas";

%let mon='04';
%let day='08';
%let cf=9901;
%let dt=362;
data _null_; call symput("sasd",compress(mdy(&mon,&day,'2020'))); ;run;
%put NOTE: using this date: &sasd, Confirmed:&cf Deaths:&dt;
%addData(1,Georgia-US,&sasd,&cf,&dt);
%include "&progpath./GenerateIndividualPlots.sas";


