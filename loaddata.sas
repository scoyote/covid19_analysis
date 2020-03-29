%put ERROR: WARNING! THIS PROGAM HAS BEEN SUPERCEDED BY HARDLOADDATA.SAS and MACROS.SAS;
%put ERROR: WARNING! THIS PROGAM HAS BEEN SUPERCEDED BY HARDLOADDATA.SAS and MACROS.SAS;
%put ERROR: WARNING! THIS PROGAM HAS BEEN SUPERCEDED BY HARDLOADDATA.SAS and MACROS.SAS;
%put ERROR: WARNING! THIS PROGAM HAS BEEN SUPERCEDED BY HARDLOADDATA.SAS and MACROS.SAS;
%put ERROR: WARNING! THIS PROGAM HAS BEEN SUPERCEDED BY HARDLOADDATA.SAS and MACROS.SAS;

*****************************************************************
***** loaddata.sas
***** pulls and prepares csv data from covid19;
*****************************************************************
;

%let rc = %sysfunc(dlgcdir("/covid_analysis"));
libname covid '/covid19data';

   
%let covidpath=/covid19data/csse_covid_19_data/csse_covid_19_daily_reports;           
filename covid19 "&covidpath";
;
/* use the data step to read the JHU data directory and 
	create macro variable arrays of filenames*/
data filenames;
  handle=dopen('covid19');
  if handle > 0 then do;
  	fnumber=0;
    count=dnum(handle);
    do i=1 to count;
      memname=dread(handle,i);
      filepref = scan(memname,1,'.');
      fileext = scan(memname,2,".");
      if fileext = "csv" then do;
      	output;
      	fnumber+1;
      	put memname= "so processing it...";
	      /* save the filename in macro variable array for input to proc import */
	      call symput(compress("fname"||fnumber),compress(memname));
	      /* grab the file name and reformat it for SAS, and a handy yyyymmdd */
	      
	      year=scan(filepref,3,'-');
	      month=scan(filepref,1,'-');
	      day=scan(filepref,2,'-');
	      /* Save down the sas output filename to a macro variable array for proc import*/
	      call symput(compress("sasname"||fnumber),compress(cats(year,month,day))); 
	   end;
    end;
    
    call symput("totFiles", compress(fnumber));
  end;
  rc=dclose(handle);
run;


proc sql noprint;
	select compress(memname) 
		into :fname1 - :fname&totFiles
		from filenames
		where fileext='csv'
		order by filepref desc;
	select compress(cats(scan(scan(memname,1,"."),3,"-"),scan(scan(memname,1,"."),1,"-"),scan(scan(memname,1,"."),2,"-"))) 
		into :sasname1 - :sasname&totFiles 
		from filenames
		where fileext='csv'
		order by filepref desc;
	select "JHU"||compress(cats(scan(scan(memname,1,"."),3,"-"),scan(scan(memname,1,"."),1,"-"),scan(scan(memname,1,"."),2,"-"))) 
		into :sasnames separated by " " 
		from filenames
		where fileext='csv'
		order by filepref;
quit;

%macro JHUtoCSV(debug=F);
	%if &debug = F %then %do;
		%put "Executing CSV Import";
		%do i=1 %to &totFiles;
			%put **********************************************;
			%put **********************************************;
			%put File Pointer &i: &&fname&i &&sasname&i;
			%put **********************************************;
			proc import 
				datafile="&covidpath./&&fname&i" 
				out=JHU&&sasname&i
				DBMS=csv
				replace;
				guessingrows=200000;
			data JHU&&sasname&i; 
				length  'province/state'n $50
					    'Country/Region'n $50
						province_state $50
						country_region $50
						length filedate $8;
				set JHU&&sasname&i;;
				filedate=&&sasname&i;
			run;
		%end;
	%end;
	%if &debug = T %then %do;
		%put Just listing file debug information;
		%put there are &totFiles files;
		%do i=1 %to &totFiles;
			%put File Pointer &i: &&fname&i &&sasname&i;
		%end;
	%end;
%mend JHUtoCSV;
%JHUtoCSV;*(debug=T);

data JHU_Legacy;
	set 
	 JHU20200122 JHU20200123 JHU20200124 JHU20200125 JHU20200126 JHU20200127 JHU20200128 JHU20200129 JHU20200130 JHU20200131 JHU20200201 
	 JHU20200202 JHU20200203 JHU20200204 JHU20200205 JHU20200206 JHU20200207 JHU20200208 JHU20200209 JHU20200210 JHU20200211 JHU20200212 
	 JHU20200213 JHU20200214 JHU20200215 JHU20200216 JHU20200217 JHU20200218 JHU20200219 JHU20200220 JHU20200221 JHU20200222 JHU20200223 
	 JHU20200224 JHU20200225 JHU20200226 JHU20200227 JHU20200228 JHU20200229 JHU20200301 JHU20200302 JHU20200303 JHU20200304 JHU20200305 
	 JHU20200306 JHU20200307 JHU20200308 JHU20200309 JHU20200310 JHU20200311 JHU20200312 JHU20200313 JHU20200314 JHU20200315 JHU20200316 
	 JHU20200317 JHU20200318 JHU20200319 JHU20200320 JHU20200321;
	 province_state='province/state'n;
	 country_region='Country/Region'n;
	drop 'province/state'n 'Country/Region'n;
run;
%put &sasnames;
/* proc datasets library=work nolist; */
/*    modify JHU_LEGACY; */
/*       rename "Province/State"n=province_state; */
/*       rename "Country/Region"n=country_region; */
/* quit; */

data JHU_current; 
	length  combined_key $50;
	format province_state $50. ;
	set JHU20200322 JHU20200323 JHU20200324 JHU20200325 JHU20200326
	JHU20200327 JHU20200328;
	drop combined_key 'province/state'n 'Country/Region'n;
run;
data jhu_final;
	set jhu_current jhu_legacy;
run;

