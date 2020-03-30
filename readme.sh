
This repository contiains code and graphs produced by that code from publically available data. The data is curated and released by Johns Hopkins University and is available at https://github.com/CSSEGISandData/COVID-19.

The SAS programs contained in this repository are not generalized yet (as of 3/29/2020) but can be used easy enough by 
1) cloning the JHU repository
2) modifying paths in the code to accomodate this location

The code is roughly generalized and I will continue to make it more general as time goes by.



docker run -it --name sas_94v1 -v /Users/samuelcroker/Documents/repositories/covid19_analysis/:/covid_analysis -v /Users/samuelcroker/Documents/repositories/COVID-19:/covid19data -p 38080:38080 registry.unx.sas.com/sacrok/sas94_centos7:latest /bin/bash 
