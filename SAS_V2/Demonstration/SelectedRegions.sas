%let codepath=/repositories/covid19_analysis/SAS_V2/Demonstration;
%let rc = %sysfunc(dlgcdir("&codepath")); 
%include 'MACROS.sas';
%include '/repositories/covid19_analysis/SAS_V2/MACROS.sas';
libname pCovid '/repositories/covid19_analysis/SAS_V2/data';

%let back=60;

%let a=no;
options papersize=legal orientation=landscape &a.symbolgen &a.mlogic &a.mprint;
ods graphics on / reset width=13.5in height=8in imagemap outputfmt=svg imagefmt=svg; 

%plotregion(US,Georgia,key=0,numback=&back);
%plotregion(US,Georgia,key="Cherokee, Georgia, US",numback=&back);
%plotregion(US,Georgia,key="Cobb, Georgia, US",numback=&back);
%plotregion(US,Georgia,key="Fulton, Georgia, US",numback=&back);
%plotregion(US,Georgia,key="Gwinnett, Georgia, US",numback=&back);
%plotregion(US,Georgia,key="DeKalb, Georgia, US",numback=&back);
%plotregion(US,Georgia,key="Fayette, Georgia, US",numback=&back);
%plotregion(US,Georgia,key="Douglas, Georgia, US",numback=&back);
%plotregion(US,Georgia,key="Clayton, Georgia, US",numback=&back);
%plotregion(US,Georgia,key="Henry, Georgia, US",numback=&back);
%plotregion(US,Georgia,key="Rockdale, Georgia, US",numback=&back);

%plotregion(US,North Carolina,key="Forsyth, North Carolina, US",numback=&back);
%plotregion(US,North Carolina,key="Guilford, North Carolina, US",numback=&back);

%plotregion(US,South Carolina,key="Anderson, South Carolina, US",numback=&back);
%plotregion(US,South Carolina,key="Greenville, South Carolina, US",numback=&back);
%plotregion(US,South Carolina,key="Charleston, South Carolina, US",numback=&back);
%plotregion(US,South Carolina,key="Horry, South Carolina, US",numback=&back);

%plotregion(US,Georgia,key=0,numback=&back);
%plotregion(US,Texas,key=0,numback=&back);
%plotregion(US,Florida,key=0,numback=&back);
%plotregion(US,South Carolina,key=0,numback=&back);
%plotregion(US,North Carolina,key=0,numback=&back);
%plotregion(US,Tennessee,key=0,numback=&back);
%plotregion(US,Alabama,key=0,numback=&back);
%plotregion(US,Louisiana,key=0,numback=&back);

%plotregion(US,Nevada,key=0,numback=&back);
%plotregion(US,Arizona,key=0,numback=&back);
%plotregion(US,California,key=0,numback=&back);


%plotregion(US,Ohio,key=0,numback=&back);
%plotregion(US,Indiana,key=0,numback=&back);
%plotregion(US,Kentucky,key=0,numback=&back);
%plotregion(US,Tennessee,key=0,numback=&back);



%plotregion(US,New York,key=0,numback=90);

%plotregion(GL,US,key=0,numback=60);
%plotregion(GL,Brazil,key=0,numback=&back);
%plotregion(GL,India,key=0,numback=&back);
%plotregion(GL,Mexico,key=0,numback=&back);
%plotregion(GL,Russia,key=0,numback=&back);
%plotregion(GL,Bangladesh,key=0,numback=&back);
%plotregion(GL,South Africa,key=0,numback=&back);
%plotregion(GL,Colombia,key=0,numback=&back);
%plotregion(GL,Peru,key=0,numback=&back);