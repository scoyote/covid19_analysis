

%PlotInd(,Georgia,-US);


%PlotInd(,Massachusetts,-US);
%PlotInd(,California,-US);
%PlotInd(,Illinois,-US);
%PlotInd(,Florida,-US);
%PlotInd(,Texas,-US);
%PlotInd(,New York,-US);
%PlotInd(,New Jersey,-US);
%PlotInd(,South Carolina,-US);
%PlotInd(,North Carolina,-US);
%PlotInd(,New Hampshire,-US);
%PlotInd(,Louisiana,-US);
%PlotInd(,Michigan,-US);
%PlotInd(,Pennsylvania,-US);


%PlotInd(Nation:,United Kingdom,);
%PlotInd(Nation:,US,);
%PlotInd(Nation:,Spain,);
%PlotInd(Nation:,Italy,);
%PlotInd(Nation:,Iran,);
%PlotInd(Nation:,France,);
%PlotInd(Nation:,Turkey,);
%PlotInd(Nation:,Belgium,);
%PlotInd(Nation:,Netherlands,);

%PlotInd(Nation:,Germany,);
%PlotInd(Nation:,Russia,);
%PlotInd(Nation:,India,);
%PlotInd(Nation:,Japan,);


/* proc sql; */
/* select country_region, sum(confirmed) as confirmed from  WORK.JHU_CORE_LOC_CENSUS_ICU_SUMMARY  */
/* group by country_region; */
/* quit; */

