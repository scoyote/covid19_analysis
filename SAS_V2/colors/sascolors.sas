

%COLORMAC;


/*
Data set providing the names and RGB, HLS values of all SAS colornames
From ftp.sas.com/techsup/downloads/sample/graph/other-colors.html

SAS/Graph accepts various color names/values types such as:

DisplayManager (DM) : 14 color names (e.g. DMBLUE , SYSBACK, SYSFORE )
Basic : 40 color names (  e.g. ORANGE, BLACK, some are full names, some are their abbreviations P=PURPLE)
KaltianNames: prefix+prefix+hue+hue (VLIBG)
Grayscale: GRAYdd or GREYdd or GRAYISHdd or GREYISH (dd in hex 0-255)
RGB : CXrrggbb (rr, gg, bb in hex 0-255)
CNS: string (e.g. Very Dark Reddish Purple)
HLS: Hhhhllss (hhh in hex 0-360, ll and ss in hex 0-255)
HTMLname: (string e.g. AliceBlue) . These color names are stored in the SAS registry.
HTMLrbg: #rrggbb  ( rr, gg, bb in hex 0-255)
CMYK: ccmmyykk (cc, mm, yy, kk in hex 0-255)
HSV: Vhhhssvv ( hhh in hex 0-360, ss and vv in hex 0-255)

*/

data sascolors(label='SAS/Graph colors');
   length rgb hls name group $ 8;
   length colorname $ 30;
   input name red green blue hue lite sat colorname &$;
   rgb =  'CX' || put(red,hex2.) || put(green,hex2.) || put(blue,hex2.);
   hls =  'hue' || put(hue,hex3.) || put(lite,hex2.) || put(sat,hex2.);
   group = lowcase(scan(colorname,-1));
   label
    colorname = 'SAS color name'
	name = 'Short color name'
    rgb = 'SAS RGB code'
    hls = 'SAS HLS code'
	red = 'Red value (0-255)'
	green = 'Green value (0-255)'
	blue = 'Blue value (0-255)'
	hue = 'Hue (0-360)'
	lite = 'Lightness (0-255)'
	sat = 'Saturation (0-255)'
	;
	ru=ranuni(&seedit);
	value=_n_;
	retain ID 'stcAttr';
	color=name;
	fillcolor=color;
	
/* 	keep id color colorname fillcolor value group; */
datalines;
GREEN      000 255 000  240 128 255    Green
BLUE       000 000 255  000 128 255    Blue
PURPLE     112 048 112  060 080 102    Purple
VIOLET     176 144 208  030 176 103    Violet
ORANGE     255 128 000  150 128 255    Orange
PINK       255 000 128  089 128 255    Pink
CYAN       000 255 255  300 128 255    Cyan
MAGENTA    255 000 255  060 128 255    Magenta
BROWN      160 080 000  150 080 255    Brown
GOLD       255 170 000  160 128 255    Gold
LIME       192 255 129  210 192 255    Lime
GRAY       128 128 128  000 128 000    Gray
LILAC      224 096 144  098 160 172    Lilac
MAROON     112 000 000  120 056 255    Maroon
RED        255 000 000  120 128 255    Red
SALMON     255 000 085  100 128 255    Salmon
TAN        224 168 096  154 160 172    Tan
ROSE       255 096 096  120 176 255    Rose
VIPK       204 027 059  109 116 195    Vivid pink
STPK       217 087 110  109 152 161    Strong pink
DEPK       153 041 061  109 097 148    Deep pink
LIPK       229 153 167  109 191 153    Light pink
MOPK       186 124 135  109 155 079    Moderate pink
DAPK       153 092 103  109 122 064    Dark pink
VIR        051 007 015  109 029 195    Vivid red
STR        115 023 039  109 069 170    Strong red
DER        076 025 035  109 051 128    Deep red
VDER       025 010 013  109 018 109    Very deep red
MOR        115 046 058  109 080 109    Moderate red
DAR        064 038 043  109 051 064    Dark red
VDAR       025 018 019  109 022 045    Very dark red
LIGRR      153 112 120  109 133 042    Light grayish red
GRR        115 084 090  109 099 039    Grayish red
DAGRR      069 060 061  109 064 018    Dark grayish red
BLR        025 023 023  109 024 013    Blackish red
RGR        140 131 133  109 136 010    Reddish gray
DARGR      089 083 084  109 086 009    Dark reddish gray
RBK        025 025 025  109 025 004    Reddish black
VIYPK      204 043 027  125 116 195    Vivid yellowish pink
STYPK      204 093 082  125 143 139    Strong yellowish pink
DEYPK      153 051 041  125 097 148    Deep yellowish pink
LIYPK      229 160 153  125 191 153    Light yellowish pink
MOYPK      191 133 128  125 159 085    Moderate yellowish pink
DAYPK      153 097 092  125 122 064    Dark yellowish pink
PAYPK      229 197 194  125 212 104    Pale yellowish pink
GRYPK      191 165 162  125 177 048    Grayish yellowish pink
BRPK       191 185 166  165 178 042    Brownish pink
VIRO       128 048 009  140 068 223    Vivid reddish orange
STRO       140 065 028  140 084 170    Strong reddish orange
DERO       102 047 020  140 061 170    Deep reddish orange
MORO       140 084 056  140 098 109    Moderate reddish orange
DARO       102 061 041  140 071 109    Dark reddish orange
GRRO       140 103 084  140 112 064    Grayish reddish orange
STRBR      076 039 020  140 048 148    Strong reddish brown
DERBR      038 021 013  140 025 128    Deep reddish brown
LIRBR      140 115 103  140 122 039    Light reddish brown
MORBR      089 069 059  140 074 051    Moderate reddish brown
DARBR      025 022 020  140 023 028    Dark reddish brown
LIGRRBR    140 125 117  140 129 024    Light grayish reddish brown
GRRBR      089 079 074  140 082 023    Grayish reddish brown
DAGRRBR    051 046 044  140 048 018    Dark grayish reddish brown
VIO        178 099 006  152 092 239    Vivid orange
BIO        217 137 043  152 130 177    Brilliant orange
STO        166 105 033  152 099 170    Strong orange
DEO        128 081 026  152 077 170    Deep orange
LIO        217 164 101  152 159 153    Light orange
MOO        166 125 077  152 122 093    Moderate orange
BRO        128 096 060  152 094 093    Brownish orange
STBR       089 059 024  152 057 148    Strong brown
DEBR       038 028 015  152 027 109    Deep brown
LIBR       140 121 098  152 119 045    Light brown
MOBR       089 078 065  152 077 039    Moderate brown
DABR       025 023 020  152 023 028    Dark brown
LIGRBR     140 136 122  165 131 019    Light grayish brown
GRBR       089 086 077  165 083 018    Grayish brown
DAGRBR     051 050 046  165 048 013    Dark grayish brown
LIBRGR     140 136 131  152 136 010    Light brownish gray
BRGR       089 087 083  152 086 009    Brownish gray
BRBL       001 001 001  152 001 001    Brownish black
VIOY       191 145 006  165 099 239    Vivid orange yellow
BIOY       229 184 046  165 138 200    Brilliant orange yellow
STOY       191 153 038  165 115 170    Strong orange yellow
DEOY       153 122 031  165 092 170    Deep orange yellow
LIOY       229 199 107  165 168 180    Light orange yellow
MOOY       186 161 087  165 137 107    Moderate orange yellow
DAOY       153 133 071  165 112 093    Dark orange yellow
PAOY       229 212 161  165 195 146    Pale orange yellow
STYBR      128 106 043  165 085 127    Strong yellowish brown
DEYBR      051 046 020  170 036 109    Deep yellowish brown
LIYBR      166 159 122  170 144 051    Light yellowish brown
MOYBR      115 110 088  170 101 034    Moderate yellowish brown
DAYBR      038 037 031  170 034 028    Dark yellowish brown
LIGRYBR    166 161 138  170 152 034    Light grayish yellowish brown
GRYBR      115 112 096  170 105 023    Grayish yellowish brown
DAGRYBR    064 062 055  170 059 018    Dark grayish yellowish brown
VIY        153 191 026  194 108 195    Vivid yellow
BIY        198 229 092  194 161 186    Brilliant yellow
STY        163 191 070  194 131 124    Strong yellow
DEY        131 153 056  194 105 118    Deep yellow
LIY        205 229 122  194 176 173    Light yellow
MOY        171 191 102  194 147 105    Moderate yellow
DAY        137 153 082  194 117 078    Dark yellow
PAY        217 229 176  194 203 131    Pale yellow
GRY        181 191 147  194 169 066    Grayish yellow
DAGRY      142 153 107  194 130 047    Dark grayish yellow
YWH        232 237 213  194 225 102    Yellowish white
YGR        187 191 172  194 182 033    Yellowish gray
LIOLBR     139 140 075  181 108 078    Light olive brown
MOOLBR     089 089 054  181 071 064    Moderate olive brown
DAOLBR     038 038 028  181 033 039    Dark olive brown
VIGY       128 191 026  203 108 195    Vivid greenish yellow
BIGY       174 229 084  203 157 189    Brilliant greenish yellow
STGY       141 186 068  203 127 118    Strong greenish yellow
DEGY       116 153 056  203 105 118    Deep greenish yellow
LIGY       189 229 122  203 176 173    Light greenish yellow
MOGY       157 191 102  203 147 105    Moderate greenish yellow
DAGY       126 153 082  203 117 078    Dark greenish yellow
PAGY       203 229 161  203 195 146    Pale greenish yellow
GRGY       169 191 134  203 163 079    Grayish greenish yellow
LIOL       098 128 051  203 089 109    Light olive
MOOL       071 089 042  203 065 093    Moderate olive
DAOL       022 025 017  203 021 051    Dark olive
LIGROL     131 140 117  203 129 024    Light grayish olive
GROL       084 089 074  203 082 023    Grayish olive
DAGROL     048 051 044  203 048 018    Dark grayish olive
LIOLGR     135 140 126  203 133 015    Light olive gray
OLGR       087 089 083  203 086 009    Olive gray
OLBL       025 025 025  203 025 000    Olive black
VILG       068 166 022  221 094 195    Vivid yellow green
BILG       136 229 092  221 161 186    Brilliant yellow green
STLG       091 153 061  221 107 109    Strong yellow green
DELG       060 102 041  221 071 109    Deep yellow green
LILG       177 229 153  221 191 153    Light yellow green
MOLG       118 153 102  221 127 051    Moderate yellow green
PALG       209 229 199  221 214 096    Pale yellow green
GRLG       139 153 133  221 143 023    Grayish yellow green
STOLG      038 076 020  221 048 148    Strong olive green
DEOLG      021 038 013  221 025 128    Deep olive green
MOOLG      069 089 059  221 074 051    Moderate olive green
DAOLG      031 038 028  221 033 039    Dark olive green
GROLG      139 153 133  221 143 023    Grayish olive green
DAGROLG    046 051 044  221 048 018    Dark grayish olive green
VIYG       022 166 041  248 094 195    Vivid yellowish green
BIYG       082 204 098  248 143 139    Brilliant yellowish green
STYG       056 140 067  248 098 109    Strong yellowish green
DEYG       024 089 032  248 057 148    Deep yellowish green
VDEYG      010 038 014  248 024 148    Very deep yellowish green
VLIYG      158 237 168  248 198 176    Very light yellowish green
LIYG       128 191 136  248 159 085    Light yellowish green
MOYG       093 140 100  248 117 051    Moderate yellowish green
DAYG       059 089 063  248 074 051    Dark yellowish green
VDAYG      023 033 024  248 028 045    Very dark yellowish green
VIG        017 128 068  268 072 195    Vivid green
BIG        077 191 129  268 134 121    Brilliant green
STG        046 115 078  268 080 109    Strong green
DEG        020 051 034  268 036 109    Deep green
VLIG       153 229 188  268 191 153    Very light green
LIG        110 166 136  268 138 060    Light green
MOG        076 115 094  268 096 051    Moderate green
DAG        054 076 064  268 065 045    Dark green
VDAG       018 025 021  268 022 045    Very dark green
VPAG       188 217 197  259 202 070    Very pale green
PAG        144 166 154  268 155 028    Pale green
GRG        099 115 106  268 107 018    Grayish green
DAGRG      069 076 072  268 073 013    Dark grayish green
BLG        023 025 024  268 024 013    Blackish green
GWH        236 237 236  248 237 006    Greenish white
LIGGR      191 191 191  248 191 001    Light greenish gray
GGR        140 140 140  248 140 001    Greenish gray
DAGGR      089 089 089  248 089 000    Dark greenish gray
GBL        025 025 025  248 025 000    Greenish black
VIBG       019 140 137  298 079 195    Vivid bluish green
BIBG       077 191 188  298 134 121    Brilliant bluish green
STBG       046 115 113  298 080 109    Strong bluish green
DEBG       020 051 050  298 036 109    Deep bluish green
VLIBG      144 217 215  298 181 124    Very light bluish green
LIBG       110 166 164  298 138 060    Light bluish green
MOBG       076 115 114  298 096 051    Moderate bluish green
DABG       045 064 063  298 054 045    Dark bluish green
VDABG      018 025 025  298 022 045    Very dark bluish green
VIGB       019 071 140  334 079 195    Vivid greenish blue
BIGB       077 126 191  334 134 121    Brilliant greenish blue
STGB       046 076 115  334 080 109    Strong greenish blue
DEGB       020 034 051  334 036 109    Deep greenish blue
VLIGB      144 176 217  334 181 124    Very light greenish blue
LIGB       110 134 166  334 138 060    Light greenish blue
MOGB       076 093 115  334 096 051    Moderate greenish blue
DAGB       042 052 064  334 053 051    Dark greenish blue
VDAGB      018 021 025  334 022 045    Very dark greenish blue
VIB        009 007 102  001 054 223    Vivid blue
BIB        050 048 178  001 113 148    Brilliant blue
STB        032 031 115  001 073 148    Strong blue
DEB        016 015 038  001 027 109    Deep blue
VLIB       118 116 217  001 166 145    Very light blue
LIB        090 088 166  001 127 078    Light blue
MOB        062 061 115  001 088 078    Moderate blue
DAB        027 027 038  001 033 045    Dark blue
VPAB       174 173 217  001 195 092    Very pale blue
PAB        133 133 166  001 149 040    Pale blue
GRB        092 092 115  001 103 028    Grayish blue
DAGRB      055 055 064  001 059 018    Dark grayish blue
BLB        023 023 025  001 024 013    Blackish blue
BWH        222 221 237  001 229 078    Bluish white
LIBGR      179 178 191  001 185 023    Light bluish gray
BGR        131 131 140  001 136 010    Bluish gray
DABGR      083 083 089  001 086 009    Dark bluish gray
BBL        025 025 025  001 025 001    Bluish black
VIPB       043 007 102  023 054 223    Vivid purplish blue
BIPB       097 048 178  023 113 148    Brilliant purplish blue
STPB       063 031 115  023 073 148    Strong purplish blue
DEPB       024 015 038  023 027 109    Deep purplish blue
VLIPB      163 122 229  023 176 173    Very light purplish blue
LIPB       109 082 153  023 117 078    Light purplish blue
MOPB       063 048 089  023 068 078    Moderate purplish blue
DAPB       021 018 025  023 022 045    Dark purplish blue
VPAPB      192 168 229  023 199 139    Very pale purplish blue
PAPB       138 122 166  023 144 051    Pale purplish blue
GRPB       074 065 089  023 077 039    Grayish purplish blue
VIV        083 009 140  034 075 223    Vivid violet
BIV        121 048 178  034 113 148    Brilliant violet
STV        060 024 089  034 057 148    Strong violet
DEV        027 013 038  034 025 128    Deep violet
VLIV       172 116 217  034 166 145    Very light violet
LIV        122 082 153  034 117 078    Light violet
MOV        071 048 089  034 068 078    Moderate violet
DAV        022 018 025  034 022 045    Dark violet
VPAV       203 168 229  034 199 139    Very pale violet
PAV        135 112 153  034 133 042    Pale violet
GRV        079 065 089  034 077 039    Grayish violet
VIP        111 009 128  052 068 223    Vivid purple
BIP        160 048 178  052 113 148    Brilliant purple
STP        103 031 115  052 073 148    Strong purple
DEP        062 023 069  052 046 128    Deep purple
VDEP       023 008 025  052 017 127    Very deep purple
VLIP       203 116 217  052 166 145    Very light purple
LIP        155 088 166  052 127 078    Light purple
MOP        107 061 115  052 088 078    Moderate purple
DAP        066 048 069  052 059 045    Dark purple
VDAP       024 018 025  052 022 045    Very dark purple
VPAP       211 173 217  052 195 092    Very pale purple
PAP        161 133 166  052 149 040    Pale purple
GRP        112 092 115  052 103 028    Grayish purple
DAGRP      068 060 069  052 064 018    Dark grayish purple
BLP        025 023 025  052 024 013    Blackish purple
PWH        235 221 237  052 229 078    Purplish white
LIPGR      189 178 191  052 185 023    Light purplish gray
PGR        139 131 140  052 136 010    Purplish gray
DAPGR      088 083 089  052 086 009    Dark purplish gray
PBL        025 025 025  052 025 001    Purplish black
VIRP       089 006 076  070 048 223    Vivid reddish purple
STRP       115 031 101  070 073 148    Strong reddish purple
DERP       069 023 062  070 046 128    Deep reddish purple
VDERP      025 008 023  070 017 127    Very deep reddish purple
LIRP       153 082 142  070 117 078    Light reddish purple
MORP       115 061 106  070 088 078    Moderate reddish purple
DARP       069 048 066  070 059 045    Dark reddish purple
VDARP      025 018 024  070 022 045    Very dark reddish purple
PARP       153 112 146  070 133 042    Pale reddish purple
GRRP       115 084 110  070 099 039    Grayish reddish purple
BIPPK      217 058 191  070 137 172    Brilliant purplish pink
STPPK      178 048 158  070 113 148    Strong purplish pink
DEPPK      153 031 133  070 092 170    Deep purplish pink
LIPPK      217 116 201  070 166 145    Light purplish pink
MOPPK      178 095 165  070 137 090    Moderate purplish pink
DAPPK      153 082 120  088 117 078    Dark purplish pink
PAPPK      229 184 208  088 207 121    Pale purplish pink
GRPPK      178 143 162  088 161 048    Grayish purplish pink
VIPR       076 005 044  088 041 223    Vivid purplish red
STPR       115 023 073  088 069 170    Strong purplish red
DEPR       069 018 046  088 044 148    Deep purplish red
VDEPR      025 010 018  088 018 109    Very deep purplish red
MOPR       115 046 083  088 080 109    Moderate purplish red
DAPR       069 041 056  088 055 064    Dark purplish red
VDAPR      025 018 022  088 022 045    Very dark purplish red
LIGRPR     153 112 134  088 133 042    Light purplish red
GRPR       115 076 097  088 096 051    Grayish purplish red
WH         255 255 255  000 255 000    White
LIGR       191 191 191  000 191 000    Light gray
MEGR       140 140 140  000 140 000    Medium gray
DAGR       089 089 089  000 089 000    Dark gray
BL         000 000 000  000 000 000    Black
LTGRAY     192 192 192  000 192 000    Light gray
DAGRAY     064 064 064  000 064 000    Dark gray
GREY       128 128 128  000 128 000    Gray
PAPK       229 191 198  109 210 109    Pale pink
CREAM      232 216 152  168 192 162    Cream
YELLOW     255 255 000  180 128 255    Yellow
GRPK       186 155 161  109 171 047    Grayish pink
PKWH       237 221 224  109 229 078    Pinkish white
PKGR       191 178 181  109 185 023    Pinkish gray
;
run;

proc sql; create table nolight as select * from sascolors 
	where 
	
		lite between 100 and 175
		and 
		group not in ('black','brown','gray','pink','yellow')
 ;
quit;
proc sort data=nolight; by value; run;
data nolight;set nolight(drop=value);
	if _n_ =1 then value=0;
	value+1;
run;


data a;
	array cols{3} $ _temporary_ ('FF','CC','E5');
	value=0;
	retain id 'c_ramp';
	do i=1 to 3;
		do j=1 to 3;
			do k=1 to 3;
				if i=1 and j=1 and k=1 then continue;
				value+1;
				color=compress('CX'||cols[i]||cols[j]||cols[k]);
				drop i j k;
				fillcolor=color;
				output;
			end;
		end;
	end;
run;

