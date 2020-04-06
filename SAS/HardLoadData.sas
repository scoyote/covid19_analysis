*****************************************************************
***** HardLoadData.sas
***** pulls and prepares csv data from covid19 using proc import
***** generated data steps. You have to run sanity checks on this
*****************************************************************;
;

%let rc = %sysfunc(dlgcdir("&covidpath"));
options nomlogic nomprint;
data _null_;
	legacy_count=0;
	current_count=0;
	handle=dopen('covid19');
	if handle > 0 then do;
		count=dnum(handle);
		do i=1 to count;
			memname=dread(handle,i);
			filepref = scan(memname,1,'.');
			fileext  = scan(memname,2,".");
			if fileext = "csv" then do;
				filedate = compress(cats(scan(filepref,3,'-'),scan(filepref,1,'-'),scan(filepref,2,'-')));
				if filedate <= '20200321' then do; /* this accounts for JHU infile structure change */
					legacy_count+1;
					call execute(cats('%LoadCSV(&covidpath/',memname,',',filedate,',',2,',',legacy_count,')'));
				end;
				else do;
					current_count+1;
					call execute(cats('%LoadCSV(&covidpath/',memname,',',filedate,',',1,',',current_count,')'));
				end;
			end;
		end;
	end;
	rc=dclose(handle);
run;

%let rc = %sysfunc(dlgcdir("&outputpath"));

