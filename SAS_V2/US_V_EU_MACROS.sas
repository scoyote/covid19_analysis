
%macro idOptima(avar,dsname,outsuffix,spread=7);
	%do i=1 %to 2;
		%if &i=1 %then %do;		
			proc sort data=&dsname out=_max&outsuffix; by glb descending filedate; run;
			data _max&outsuffix; set _max&outsuffix;
				by glb descending filedate;
		%end;
		%else %do;		
			proc sort data=_max&outsuffix;  by glb filedate; run;
			data _max&outsuffix; set _max&outsuffix;
				by glb filedate;
		%end;
			array direction(2) $ dr df; 
			array dirar(2) $ _TEMPORARY_  ('u','d');
			if first.glb then do;
				ctr=0;
				glbl=substr(glb,1,1);
				mp = 0;
			end;
			mp = lag(&avar);
			&avar=int(&avar);
			if ctr>0 then do;
				if &avar = mp then do;
					direction[&i]='s';
				end;
				else if &avar > mp then do;
					direction[&i]=dirar[1];
				end;
				else if &avar < mp then do;
					direction[&i]=dirar[2];
				end;
				else direction[&i]='0';
			end;
			ctr+1;
		run;
	%end;
	data _max _min _optimized; 
		set _max&outsuffix;
		if df = 'u' and dr='u' then output _max;
		else if df = 'd' and dr='d' then output _min;
		output _optimized;
	run;

	/* Separate MIN MAX */
	proc sort data=_max; by glb descending &avar filedate; run;
	%do i=1 %to 2;
		%if &I=1 %then %do;
			data _max; set _max(keep=filedate glb &avar);
			by glb descending &avar;
			opttype='MAX';
		%end;
		%if &I=2 %then %do;
			proc sort data=_min; by glb &avar;
			data _min; set _min(keep=filedate glb &avar where=(filedate>=&umax1c)) ;
			by glb &avar;
			opttype='MIN';
		%end;
			if first.glb then do;
				ctr=0;
				glbl=substr(glb,1,1);
			end;
			glbl=substr(glb,1,1);
			maxdate=filedate;
			interval=intck('day',lag(filedate),maxdate);
			if ctr>0 and abs(interval) <= 7  then do;
				delete;
			end;
			else do;
				maxdate=filedate;
				CALL SYMPUTX(compress(substr(glb,1,1)||left(opttype)||left(ctr+1)||left("&outsuffix")),FILEDATE,'g');
				ctr+1;
			end;
			if last.glb then CALL SYMPUTX(compress(substr(glb,1,1)||left(opttype)||"_CT"),ctr,'g');
			drop ctr;
		run;
	%end;	
%mend; 




%macro GetEstimates;
	proc sort data=_optimized; by glb filedate; run;
	data _optimized; set _optimized(keep=filedate glb &avar);
		by glb descending &avar;
		if first.glb then do;
			ctr=0;
			glbl=substr(glb,1,1);
		end;
		glbl=substr(glb,1,1);
		maxdate=filedate;
		interval=intck('day',lag(filedate),maxdate);
		if ctr>0 and abs(interval) <= 7  then do;
			delete;
		end;
		else do;
			maxdate=filedate;
			CALL SYMPUTX(compress(substr(glb,1,1)||left(opttype)||left(ctr)||"C"),FILEDATE,G);
			ctr+1;
		end;
		if last.glb then 
			CALL SYMPUTX(compress(substr(glb,1,1)||left(opttype)||"_COUNT"||"C",ctr,G);
		drop ctr;
	run;
%mend GetEstimates;




