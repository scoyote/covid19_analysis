/* clean up from previous runs if necessary */
proc datasets library=WORK kill; run; quit;
%global adjust_note	adjust_date adjust_confirmed adjust_deaths;

%let covidpath=/covid19data/csse_covid_19_data/csse_covid_19_daily_reports;
%let progpath=/covid_analysis;
%let outputpath=/covid_analysis/graphs/;

libname covid '/covid19data';   
libname fips "&progpath./data";        
filename covid19 "&covidpath";
