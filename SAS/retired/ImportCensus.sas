data _null_;
put 'WARNING: This loads into WORK as is.' ;
put 'WARNING:   Change line 12 to line 13 to make permanent';
put 'WARNING:   - but only after you are assured that the following url is good';
put 'WARNING:   Source Information: https://www.census.gov/data/tables/time-series/demo/popest/2010s-counties-total.html';
put 'WARNING:   Data URL: https://www2.census.gov/programs-surveys/popest/datasets/2010-2019/counties/totals/co-est2019-alldata.csv' ///;
run;

/* Source Info: https://www.census.gov/data/tables/time-series/demo/popest/2010s-counties-total.html*/
filename census url 'https://www2.census.gov/programs-surveys/popest/datasets/2010-2019/counties/totals/co-est2019-alldata.csv';

/* proc import file=census */
/*     DBMS=CSV */
/* 	OUT=FIPS.population_estimates; */
/* 	GETNAMES=YES; */
/* 	DATAROW=2; */
/* 	GUESSINGROWS=20000; */
/* RUN; */
data work.POPULATION_ESTIMATES;
*data FIPS.POPULATION_ESTIMATES;
	infile CENSUS delimiter = ',' MISSOVER DSD lrecl=32767 firstobs=2 ;

informat fips_join $5. ;
		
	informat SUMLEV $5. ;
	informat REGION $5. ;
	informat DIVISION $5. ;
	informat STATE  $5. ;
	informat COUNTY  $5. ;
	informat STNAME $100. ;
	informat CTYNAME $100. ;
	
	 informat CENSUS2010POP best32. ;
	 informat ESTIMATESBASE2010 best32. ;
	 informat POPESTIMATE2010 best32. ;
	 informat POPESTIMATE2011 best32. ;
	 informat POPESTIMATE2012 best32. ;
	 informat POPESTIMATE2013 best32. ;
	 informat POPESTIMATE2014 best32. ;
	 informat POPESTIMATE2015 best32. ;
	 informat POPESTIMATE2016 best32. ;
	 informat POPESTIMATE2017 best32. ;
	 informat POPESTIMATE2018 best32. ;
	 informat POPESTIMATE2019 best32. ;
	 informat NPOPCHG_2010 best32. ;
	 informat NPOPCHG_2011 best32. ;
	 informat NPOPCHG_2012 best32. ;
	 informat NPOPCHG_2013 best32. ;
	 informat NPOPCHG_2014 best32. ;
	 informat NPOPCHG_2015 best32. ;
	 informat NPOPCHG_2016 best32. ;
	 informat NPOPCHG_2017 best32. ;
	 informat NPOPCHG_2018 best32. ;
	 informat NPOPCHG_2019 best32. ;
	 informat BIRTHS2010 best32. ;
	 informat BIRTHS2011 best32. ;
	 informat BIRTHS2012 best32. ;
	 informat BIRTHS2013 best32. ;
	 informat BIRTHS2014 best32. ;
	 informat BIRTHS2015 best32. ;
	 informat BIRTHS2016 best32. ;
	 informat BIRTHS2017 best32. ;
	 informat BIRTHS2018 best32. ;
	 informat BIRTHS2019 best32. ;
	 informat DEATHS2010 best32. ;
	 informat DEATHS2011 best32. ;
	 informat DEATHS2012 best32. ;
	 informat DEATHS2013 best32. ;
	 informat DEATHS2014 best32. ;
	 informat DEATHS2015 best32. ;
	 informat DEATHS2016 best32. ;
	 informat DEATHS2017 best32. ;
	 informat DEATHS2018 best32. ;
	 informat DEATHS2019 best32. ;
	 informat NATURALINC2010 best32. ;
	 informat NATURALINC2011 best32. ;
	 informat NATURALINC2012 best32. ;
	 informat NATURALINC2013 best32. ;
	 informat NATURALINC2014 best32. ;
	 informat NATURALINC2015 best32. ;
	 informat NATURALINC2016 best32. ;
	 informat NATURALINC2017 best32. ;
	 informat NATURALINC2018 best32. ;
	 informat NATURALINC2019 best32. ;
	 informat INTERNATIONALMIG2010 best32. ;
	 informat INTERNATIONALMIG2011 best32. ;
	 informat INTERNATIONALMIG2012 best32. ;
 	 informat INTERNATIONALMIG2013 best32. ;
	 informat INTERNATIONALMIG2014 best32. ;
	informat INTERNATIONALMIG2015 best32. ;
	informat INTERNATIONALMIG2016 best32. ;
	informat INTERNATIONALMIG2017 best32. ;
	informat INTERNATIONALMIG2018 best32. ;
	informat INTERNATIONALMIG2019 best32. ;
	informat DOMESTICMIG2010 best32. ;
	informat DOMESTICMIG2011 best32. ;
	informat DOMESTICMIG2012 best32. ;
	informat DOMESTICMIG2013 best32. ;
	informat DOMESTICMIG2014 best32. ;
	informat DOMESTICMIG2015 best32. ;
	informat DOMESTICMIG2016 best32. ;
	informat DOMESTICMIG2017 best32. ;
	informat DOMESTICMIG2018 best32. ;
	informat DOMESTICMIG2019 best32. ;
	informat NETMIG2010 best32. ;
	informat NETMIG2011 best32. ;
	informat NETMIG2012 best32. ;
	informat NETMIG2013 best32. ;
	informat NETMIG2014 best32. ;
	informat NETMIG2015 best32. ;
	informat NETMIG2016 best32. ;
	informat NETMIG2017 best32. ;
	informat NETMIG2018 best32. ;
	informat NETMIG2019 best32. ;
	informat RESIDUAL2010 best32. ;
	informat RESIDUAL2011 best32. ;
	informat RESIDUAL2012 best32. ;
	informat RESIDUAL2013 best32. ;
	informat RESIDUAL2014 best32. ;
	informat RESIDUAL2015 best32. ;
	informat RESIDUAL2016 best32. ;
	informat RESIDUAL2017 best32. ;
	informat RESIDUAL2018 best32. ;
	informat RESIDUAL2019 best32. ;
	informat GQESTIMATESBASE2010 best32. ;
	informat GQESTIMATES2010 best32. ;
	informat GQESTIMATES2011 best32. ;
	informat GQESTIMATES2012 best32. ;
	 informat GQESTIMATES2013 best32. ;
	 informat GQESTIMATES2014 best32. ;
	 informat GQESTIMATES2015 best32. ;
	 informat GQESTIMATES2016 best32. ;
	 informat GQESTIMATES2017 best32. ;
	 informat GQESTIMATES2018 best32. ;
	 informat GQESTIMATES2019 best32. ;
	 informat RBIRTH2011 best32. ;
	 informat RBIRTH2012 best32. ;
	 informat RBIRTH2013 best32. ;
	 informat RBIRTH2014 best32. ;
	 informat RBIRTH2015 best32. ;
	 informat RBIRTH2016 best32. ;
	 informat RBIRTH2017 best32. ;
	 informat RBIRTH2018 best32. ;
	 informat RBIRTH2019 best32. ;
	  informat RDEATH2011 best32. ;
	  informat RDEATH2012 best32. ;
	  informat RDEATH2013 best32. ;
	  informat RDEATH2014 best32. ;
	  informat RDEATH2015 best32. ;
	  informat RDEATH2016 best32. ;
	  informat RDEATH2017 best32. ;
	  informat RDEATH2018 best32. ;
	  informat RDEATH2019 best32. ;
	  informat RNATURALINC2011 best32. ;
	  informat RNATURALINC2012 best32. ;
	  informat RNATURALINC2013 best32. ;
	  informat RNATURALINC2014 best32. ;
	  informat RNATURALINC2015 best32. ;
	  informat RNATURALINC2016 best32. ;
	  informat RNATURALINC2017 best32. ;
	  informat RNATURALINC2018 best32. ;
	  informat RNATURALINC2019 best32. ;
	  informat RINTERNATIONALMIG2011 best32. ;
	  informat RINTERNATIONALMIG2012 best32. ;
	  informat RINTERNATIONALMIG2013 best32. ;
	  informat RINTERNATIONALMIG2014 best32. ;
	  informat RINTERNATIONALMIG2015 best32. ;
	  informat RINTERNATIONALMIG2016 best32. ;
	  informat RINTERNATIONALMIG2017 best32. ;
	  informat RINTERNATIONALMIG2018 best32. ;
	informat RINTERNATIONALMIG2019 best32. ;
	informat RDOMESTICMIG2011 best32. ;
	informat RDOMESTICMIG2012 best32. ;
	informat RDOMESTICMIG2013 best32. ;
	informat RDOMESTICMIG2014 best32. ;
	informat RDOMESTICMIG2015 best32. ;
	informat RDOMESTICMIG2016 best32. ;
	informat RDOMESTICMIG2017 best32. ;
	informat RDOMESTICMIG2018 best32. ;
	informat RDOMESTICMIG2019 best32. ;
	informat RNETMIG2011 best32. ;
	informat RNETMIG2012 best32. ;
	informat RNETMIG2013 best32. ;
	informat RNETMIG2014 best32. ;
	informat RNETMIG2015 best32. ;
	informat RNETMIG2016 best32. ;
	informat RNETMIG2017 best32. ;
	informat RNETMIG2018 best32. ;
	informat RNETMIG2019 best32. ;
            
	format SUMLEV  $5. ;
	format REGION  $5. ;
	format DIVISION  $5. ;
	format STATE  $5. ;
	format COUNTY $5. ;
	format STNAME $50. ;
	format CTYNAME $50. ;
	  format CENSUS2010POP comma. ;
	  format ESTIMATESBASE2010 comma. ;
	  format POPESTIMATE2010 comma. ;
	  format POPESTIMATE2011 best12. ;
	  format POPESTIMATE2012 best12. ;
	  format POPESTIMATE2013 best12. ;
	  format POPESTIMATE2014 best12. ;
	  format POPESTIMATE2015 best12. ;
	  format POPESTIMATE2016 best12. ;
	  format POPESTIMATE2017 best12. ;
	  format POPESTIMATE2018 best12. ;
	  format POPESTIMATE2019 best12. ;
	  format NPOPCHG_2010 best12. ;
	  format NPOPCHG_2011 best12. ;
	  format NPOPCHG_2012 best12. ;
	  format NPOPCHG_2013 best12. ;
	  format NPOPCHG_2014 best12. ;
	  format NPOPCHG_2015 best12. ;
	  format NPOPCHG_2016 best12. ;
	  format NPOPCHG_2017 best12. ;
	  format NPOPCHG_2018 best12. ;
	  format NPOPCHG_2019 best12. ;
	  format BIRTHS2010 best12. ;
	  format BIRTHS2011 best12. ;
	    format BIRTHS2012 best12. ;
	    format BIRTHS2013 best12. ;
	    format BIRTHS2014 best12. ;
	    format BIRTHS2015 best12. ;
	    format BIRTHS2016 best12. ;
	    format BIRTHS2017 best12. ;
	    format BIRTHS2018 best12. ;
	    format BIRTHS2019 best12. ;
	    format DEATHS2010 best12. ;
	    format DEATHS2011 best12. ;
	    format DEATHS2012 best12. ;
	    format DEATHS2013 best12. ;
	    format DEATHS2014 best12. ;
	    format DEATHS2015 best12. ;
	   format DEATHS2016 best12. ;
	   format DEATHS2017 best12. ;
	   format DEATHS2018 best12. ;
	   format DEATHS2019 best12. ;
	   format NATURALINC2010 best12. ;
	   format NATURALINC2011 best12. ;
	   format NATURALINC2012 best12. ;
	   format NATURALINC2013 best12. ;
	   format NATURALINC2014 best12. ;
	   format NATURALINC2015 best12. ;
	   format NATURALINC2016 best12. ;
	   format NATURALINC2017 best12. ;
	   format NATURALINC2018 best12. ;
	   format NATURALINC2019 best12. ;
	   format INTERNATIONALMIG2010 best12. ;
	   format INTERNATIONALMIG2011 best12. ;
	   format INTERNATIONALMIG2012 best12. ;
	   format INTERNATIONALMIG2013 best12. ;
	   format INTERNATIONALMIG2014 best12. ;
	   format INTERNATIONALMIG2015 best12. ;
	   format INTERNATIONALMIG2016 best12. ;
	   format INTERNATIONALMIG2017 best12. ;
	   format INTERNATIONALMIG2018 best12. ;
	   format INTERNATIONALMIG2019 best12. ;
	   format DOMESTICMIG2010 best12. ;
	   format DOMESTICMIG2011 best12. ;
	   format DOMESTICMIG2012 best12. ;
	   format DOMESTICMIG2013 best12. ;
	   format DOMESTICMIG2014 best12. ;
	   format DOMESTICMIG2015 best12. ;
	   format DOMESTICMIG2016 best12. ;
	   format DOMESTICMIG2017 best12. ;
	   format DOMESTICMIG2018 best12. ;
	   format DOMESTICMIG2019 best12. ;
	   format NETMIG2010 best12. ;
	   format NETMIG2011 best12. ;
	   format NETMIG2012 best12. ;
	   format NETMIG2013 best12. ;
	   format NETMIG2014 best12. ;
	   format NETMIG2015 best12. ;
	   format NETMIG2016 best12. ;
	   format NETMIG2017 best12. ;
	   format NETMIG2018 best12. ;
	   format NETMIG2019 best12. ;
	   format RESIDUAL2010 best12. ;
	   format RESIDUAL2011 best12. ;
	   format RESIDUAL2012 best12. ;
	   format RESIDUAL2013 best12. ;
	   format RESIDUAL2014 best12. ;
	   format RESIDUAL2015 best12. ;
	   format RESIDUAL2016 best12. ;
	   format RESIDUAL2017 best12. ;
	   format RESIDUAL2018 best12. ;
	   format RESIDUAL2019 best12. ;
	   format GQESTIMATESBASE2010 best12. ;
	   format GQESTIMATES2010 best12. ;
	   format GQESTIMATES2011 best12. ;
	   format GQESTIMATES2012 best12. ;
	   format GQESTIMATES2013 best12. ;
	   format GQESTIMATES2014 best12. ;
	   format GQESTIMATES2015 best12. ;
	   format GQESTIMATES2016 best12. ;
	   format GQESTIMATES2017 best12. ;
	   format GQESTIMATES2018 best12. ;
	   format GQESTIMATES2019 best12. ;
	   format RBIRTH2011 best12. ;
	   format RBIRTH2012 best12. ;
	   format RBIRTH2013 best12. ;
	   format RBIRTH2014 best12. ;
	   format RBIRTH2015 best12. ;
	   format RBIRTH2016 best12. ;
	   format RBIRTH2017 best12. ;
	   format RBIRTH2018 best12. ;
	   format RBIRTH2019 best12. ;
	   format RDEATH2011 best12. ;
	   format RDEATH2012 best12. ;
	   format RDEATH2013 best12. ;
	   format RDEATH2014 best12. ;
	   format RDEATH2015 best12. ;
	   format RDEATH2016 best12. ;
	   format RDEATH2017 best12. ;
	   format RDEATH2018 best12. ;
	   format RDEATH2019 best12. ;
	   format RNATURALINC2011 best12. ;
	   format RNATURALINC2012 best12. ;
	   format RNATURALINC2013 best12. ;
	   format RNATURALINC2014 best12. ;
	   format RNATURALINC2015 best12. ;
	   format RNATURALINC2016 best12. ;
	   format RNATURALINC2017 best12. ;
	   format RNATURALINC2018 best12. ;
	   format RNATURALINC2019 best12. ;
	   format RINTERNATIONALMIG2011 best12. ;
	   format RINTERNATIONALMIG2012 best12. ;
	   format RINTERNATIONALMIG2013 best12. ;
	   format RINTERNATIONALMIG2014 best12. ;
	   format RINTERNATIONALMIG2015 best12. ;
	   format RINTERNATIONALMIG2016 best12. ;
	   format RINTERNATIONALMIG2017 best12. ;
	   format RINTERNATIONALMIG2018 best12. ;
	   format RINTERNATIONALMIG2019 best12. ;
	   format RDOMESTICMIG2011 best12. ;
	   format RDOMESTICMIG2012 best12. ;
	   format RDOMESTICMIG2013 best12. ;
	   format RDOMESTICMIG2014 best12. ;
	   format RDOMESTICMIG2015 best12. ;
	   format RDOMESTICMIG2016 best12. ;
	   format RDOMESTICMIG2017 best12. ;
	   format RDOMESTICMIG2018 best12. ;
	   format RDOMESTICMIG2019 best12. ;
	   format RNETMIG2011 best12. ;
	   format RNETMIG2012 best12. ;
	   format RNETMIG2013 best12. ;
	   format RNETMIG2014 best12. ;
	   format RNETMIG2015 best12. ;
	   format RNETMIG2016 best12. ;
	   format RNETMIG2017 best12. ;
	   format RNETMIG2018 best12. ;
	   format RNETMIG2019 best12. ;
input
            SUMLEV
            REGION
            DIVISION
            STATE
            COUNTY
            STNAME  $
            CTYNAME  $
            CENSUS2010POP
            ESTIMATESBASE2010
            POPESTIMATE2010
            POPESTIMATE2011
            POPESTIMATE2012
            POPESTIMATE2013
            POPESTIMATE2014
            POPESTIMATE2015
            POPESTIMATE2016
            POPESTIMATE2017
            POPESTIMATE2018
           POPESTIMATE2019
           NPOPCHG_2010
           NPOPCHG_2011
           NPOPCHG_2012
           NPOPCHG_2013
           NPOPCHG_2014
           NPOPCHG_2015
           NPOPCHG_2016
           NPOPCHG_2017
           NPOPCHG_2018
           NPOPCHG_2019
           BIRTHS2010
           BIRTHS2011
           BIRTHS2012
           BIRTHS2013
           BIRTHS2014
           BIRTHS2015
           BIRTHS2016
           BIRTHS2017
           BIRTHS2018
           BIRTHS2019
           DEATHS2010
           DEATHS2011
           DEATHS2012
           DEATHS2013
           DEATHS2014
           DEATHS2015
           DEATHS2016
           DEATHS2017
           DEATHS2018
           DEATHS2019
           NATURALINC2010
           NATURALINC2011
           NATURALINC2012
           NATURALINC2013
           NATURALINC2014
           NATURALINC2015
           NATURALINC2016
           NATURALINC2017
           NATURALINC2018
         NATURALINC2019
         INTERNATIONALMIG2010
         INTERNATIONALMIG2011
         INTERNATIONALMIG2012
         INTERNATIONALMIG2013
         INTERNATIONALMIG2014
         INTERNATIONALMIG2015
         INTERNATIONALMIG2016
         INTERNATIONALMIG2017
         INTERNATIONALMIG2018
         INTERNATIONALMIG2019
         DOMESTICMIG2010
         DOMESTICMIG2011
         DOMESTICMIG2012
         DOMESTICMIG2013
         DOMESTICMIG2014
         DOMESTICMIG2015
         DOMESTICMIG2016
         DOMESTICMIG2017
         DOMESTICMIG2018
         DOMESTICMIG2019
         NETMIG2010
         NETMIG2011
         NETMIG2012
         NETMIG2013
         NETMIG2014
         NETMIG2015
         NETMIG2016
	   NETMIG2017
	   NETMIG2018
	   NETMIG2019
	   RESIDUAL2010
	   RESIDUAL2011
	   RESIDUAL2012
	   RESIDUAL2013
	   RESIDUAL2014
	   RESIDUAL2015
	   RESIDUAL2016
	   RESIDUAL2017
	   RESIDUAL2018
	   RESIDUAL2019
	   GQESTIMATESBASE2010
	   GQESTIMATES2010
	   GQESTIMATES2011
	   GQESTIMATES2012
	   GQESTIMATES2013
	   GQESTIMATES2014
	   GQESTIMATES2015
	   GQESTIMATES2016
	   GQESTIMATES2017
	   GQESTIMATES2018
	   GQESTIMATES2019
	   RBIRTH2011
	   RBIRTH2012
	   RBIRTH2013
	   RBIRTH2014
	   RBIRTH2015
	   RBIRTH2016
	   RBIRTH2017
   RBIRTH2018
   RBIRTH2019
    RDEATH2011
    RDEATH2012
    RDEATH2013
    RDEATH2014
    RDEATH2015
    RDEATH2016
    RDEATH2017
    RDEATH2018
    RDEATH2019
    RNATURALINC2011
    RNATURALINC2012
    RNATURALINC2013
    RNATURALINC2014
    RNATURALINC2015
    RNATURALINC2016
    RNATURALINC2017
	RNATURALINC2018
	RNATURALINC2019
	RINTERNATIONALMIG2011
	RINTERNATIONALMIG2012
	RINTERNATIONALMIG2013
	RINTERNATIONALMIG2014
	RINTERNATIONALMIG2015
	RINTERNATIONALMIG2016
	RINTERNATIONALMIG2017
	RINTERNATIONALMIG2018
	RINTERNATIONALMIG2019
	RDOMESTICMIG2011
	RDOMESTICMIG2012
	RDOMESTICMIG2013
	RDOMESTICMIG2014
	RDOMESTICMIG2015
	RDOMESTICMIG2016
	RDOMESTICMIG2017
	RDOMESTICMIG2018
	RDOMESTICMIG2019
	RNETMIG2011
	RNETMIG2012
	RNETMIG2013
	RNETMIG2014
	RNETMIG2015
	RNETMIG2016
	RNETMIG2017
	RNETMIG2018
	RNETMIG2019
;
	fips_join = cats(state,county) ;

run;


PROC CONTENTS DATA=FIPS.population_estimates; RUN;

