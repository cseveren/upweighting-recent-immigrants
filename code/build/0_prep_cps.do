***************************
** Create native-born dataset

use "$dta/inputs/CPS_Basic/$cps.dta", clear
keep if yrimmig==0 | bpl < 14999

gen awt = wtfinl

compress
save $dta/tmp/cps_nonimm_base.dta, replace


***************************
** Create foreign-born dataset | method 0 interpolation

use "$dta/inputs/CPS_Basic/$cps.dta", clear
drop if yrimmig==0 | bpl < 14999

joinby year yrimmig using $dta/tmp/xwalk0.dta

rename time_weight time_weight_0

save $dta/tmp/tmp_cps_imm_0.dta, replace


***************************
** Create foreign-born dataset | method A interpolation

tempfile moyr_cps_immA

use "$dta/inputs/CPS_Basic/$cps.dta", clear
drop if yrimmig==0 | bpl < 14999

** Two-step crosswalk, (1) by month for in US <=2 or <= 3 years, (2) by year for everyone else
preserve
	joinby year yrimmig month using $dta/tmp/xwalkA_yrmo.dta, _merge(_merge)
	drop _merge
	save "`moyr_cps_immA'"
restore

joinby year yrimmig using $dta/tmp/xwalkA_yryr.dta, _merge(_merge)
drop _merge 

append using "`moyr_cps_immA'"

rename time_weight time_weight_A

compress
save $dta/tmp/tmp_cps_imm_A.dta, replace


***************************
** Create foreign-born dataset | method B interpolation

tempfile moyr_cps_immB

use "$dta/inputs/CPS_Basic/$cps.dta", clear
drop if yrimmig==0 | bpl < 14999

gen f_yr = floor(cpsid/10000000000)
gen f_mo = floor( (cpsid - f_yr*10000000000)/100000000 )

gen sample_month = ym(year, month) - ym(f_yr, f_mo) + 1

** Two-step crosswalk, (1) by month for in US <=2 or <= 3 years, (2) by year for everyone else
preserve
	joinby year yrimmig month sample_month using $dta/tmp/xwalkB_yrmo.dta, _merge(_merge)
	drop _merge

	tempfile moyr_cps_immB
	save "`moyr_cps_immB'"
restore

joinby year yrimmig using $dta/tmp/xwalkB_yryr.dta, _merge(_merge)
drop _merge 

append using "`moyr_cps_immB'"

rename time_weight time_weight_B

drop f_yr f_mo sample_month
compress
save $dta/tmp/tmp_cps_imm_B.dta, replace


***************************
** Create foreign-born dataset | method C interpolation

tempfile moyrF_cps_imm method_firsts moyrL_cps_imm method_lasts

use "$dta/inputs/CPS_Basic/$cps.dta", clear
drop if yrimmig==0 | bpl < 14999

tab yrimmig year 

keep year month cpsid cpsidp cpsidv yrimmig

* create first response indicator from id
gen f1_yr = floor(cpsid/10000000000)
gen f1_mo = floor( (cpsid - f1_yr*10000000000)/100000000 )

* create first and last response indicator from observations
gen yrmo_i = 100*year + month

bys cpsidp: egen f2_yrmo = min(yrmo_i)
gen f2_yr = floor(f2_yrmo/100)
gen f2_mo = f2_yrmo - f2_yr*100

bys cpsidp: egen l_yrmo = max(yrmo_i)
gen l_yr = floor(l_yrmo/100)
gen l_mo = l_yrmo - l_yr*100

drop *yrmo*

* create separate yrimmig
gen f1_yrimmig = yrimmig if year==f1_yr & month==f1_mo
gen f2_yrimmig = yrimmig if year==f2_yr & month==f2_mo

gen f_yrimmig = f1_yrimmig if year==f1_yr & month==f1_mo
gen f_yr = f1_yr if !mi(f_yrimmig)
gen f_mo = f1_mo if !mi(f_yrimmig)

replace f_yr = f2_yr if mi(f_yrimmig) & (year==f2_yr & month==f2_mo)
replace f_mo = f2_mo if mi(f_yrimmig) & (year==f2_yr & month==f2_mo)
replace f_yrimmig = f2_yrimmig if mi(f_yrimmig) & (year==f2_yr & month==f2_mo)

gen l_yrimmig = yrimmig if year==l_yr & month==l_mo

lab values f_yrimmig yrimmig_lbl
lab values l_yrimmig yrimmig_lbl

drop f1_* f2_*

collapse (mean) l_* f_*, by(cpsidp)

lab values f_yrimmig yrimmig_lbl
lab values l_yrimmig yrimmig_lbl

order cpsidp f_yr f_mo f_yrimmig l_yr l_mo l_yrimmig

* merge on firsts then on lasts
preserve 
	gen yrimmig = f_yrimmig
	gen year = f_yr
	gen month = f_mo

	joinby year yrimmig month using $dta/tmp/xwalkA_yrmo.dta, _merge(_merge)
	drop _merge 
	
	save "`moyrF_cps_imm'"
restore
	
preserve
	gen yrimmig = f_yrimmig
	gen year = f_yr
	
	joinby year yrimmig using $dta/tmp/xwalkA_yryr.dta, _merge(_merge)
	drop _merge 

	append using "`moyrF_cps_imm'"
	
	rename time_weight time_weight_f
	
	gen yrimmig_est = f_yr - time_in_US
	
	save "`method_firsts'"
restore

preserve 
	gen yrimmig = l_yrimmig
	gen year = l_yr
	gen month = l_mo

	joinby year yrimmig month using $dta/tmp/xwalkA_yrmo.dta, _merge(_merge)
	drop _merge 
	
	save "`moyrL_cps_imm'"
restore
	
preserve
	gen yrimmig = l_yrimmig
	gen year = l_yr
	
	joinby year yrimmig using $dta/tmp/xwalkA_yryr.dta, _merge(_merge)
	drop _merge 

	append using "`moyrL_cps_imm'"
	
	rename time_weight time_weight_l
	
	gen yrimmig_est = l_yr - time_in_US
	
	save "`method_lasts'"
restore

use "`method_firsts'", clear
merge 1:1 cpsidp yrimmig_est using  "`method_lasts'"
sort cpsidp yrimmig_est
drop yrimmig year month 

bys cpsidp: egen nn = count(cpsidp)

bys cpsidp: egen m_max = max(_merge)
bys cpsidp: egen m_min = min(_merge)
	* if m_max & m_min are both <3, no overlap, mismatched answers, go back to method B
	* if m_max & m_min are both ==3, perfect overlap, go back to method B
	* if m_max==3 and m_min<3, some overlaps, room from improvement
tab time_in_US if m_max==3 & m_min<3

*browse if m_max==3 & m_min<3 & time_in_US<20
keep if m_max==3 & m_min<3 & time_in_US<20
drop time_in_US

** rules: 
	*if m_max==3 and m_min==2 --> keep earlier?
	*if m_max==3 and m_min==1 --> form intersection of weights
	*	when earlier years are both populated, take later-period weights
	*	when earlier-period last yrimmig_est are empty, upweight intersecting years to sum to one

*browse if m_max==3 & m_min==2
*browse if m_max==3 & m_min==1

gen time_weight_tt1 = time_weight_f if m_min==2 & m_max==3 

bys cpsidp: egen yri_min = min(yrimmig_est)
bys cpsidp: egen yri_max = max(yrimmig_est)

gen earlypop_tmp = (_merge==3) if m_min==1 & m_max==3 & yri_min==yrimmig_est
gen latepop_tmp = (_merge==2) if m_min==1 & m_max==3 & yri_max==yrimmig_est
bys cpsidp: egen earlypop = mean(earlypop_tmp)
bys cpsidp: egen latepop = mean(latepop_tmp)

drop earlypop_tmp latepop_tmp 

gen time_weight_tt2 = time_weight_l if m_min==1 & m_max==3 & earlypop==1
gen time_weight_tt3 = time_weight_f if m_min==1 & m_max==3 & latepop==1 & _merge==3

** checks 
foreach n of numlist 1/3 {
	bys cpsidp: egen sum_tt`n' = sum(time_weight_tt`n')
	replace sum_tt`n'=. if sum_tt`n'==0
}

egen rowcheck=rowtotal(sum_tt?)
sum rowcheck // should be no 0s and no missings
sum rowcheck if mi(sum_tt3) // should be all 1s
sum rowcheck if !mi(sum_tt3) // should be all in (0,1)

keep cpsidp yrimmig_est time_weight_tt1 time_weight_tt2 time_weight_tt3 sum_tt3
drop if mi(time_weight_tt1) & mi(time_weight_tt2) & mi(time_weight_tt3)

replace time_weight_tt3 = time_weight_tt3/sum_tt3

** clear
egen time_weight_C = rowtotal(time_weight_tt?)
drop time_weight_tt? sum_tt3

save $dta/tmp/tmp_cps_imm_C.dta, replace



***************************
** Assemble Data

use $dta/tmp/tmp_cps_imm_0.dta, clear
merge 1:1 cpsidp year month time_in_US using $dta/tmp/tmp_cps_imm_A.dta
drop _merge
merge 1:1 cpsidp year month time_in_US using $dta/tmp/tmp_cps_imm_B.dta
drop _merge

gen yrimmig_est = year - time_in_US
replace yrimmig_est=. if time_in_US==30

merge m:1 cpsidp yrimmig_est using $dta/tmp/tmp_cps_imm_C.dta // 10710183
tab _merge

replace time_weight_B = 0 if mi(time_weight_B)

bys cpsidp: egen anyC = max(_merge)

replace time_weight_C = 0 if mi(time_weight_C) & anyC==3
replace time_weight_C = time_weight_B if mi(time_weight_C) & anyC==1

** for the small number of foreign-born who given inconsistent answers on year of immigration, but
**  have first-interview and last-interview answers that are consistent... 
**  there are exactly 1000 of these people

bys cpsidp year month: egen sum_C=sum(time_weight_C)
bys cpsidp: egen min_C = min(sum_C)
	
preserve 
	drop if min_C==0 & sum_C==0
	tempfile clean_so_far
	save "`clean_so_far'"
restore

keep if min_C==0 & sum_C==0

rename yrimmig_est yrimmig_alt
rename time_weight_C time_weight_C0

preserve
	tempfile extramerge

	clear
	local yvar = ${maxyear} - 1990
	set obs `yvar'
	gen yrimmig_est=_n+1990
	save "`extramerge'"
restore

drop _merge

cross using "`extramerge'"
sort cpsidp year month yrimmig_alt yrimmig_est

merge m:1 cpsidp yrimmig_est using $dta/tmp/tmp_cps_imm_C.dta
drop if _merge==2

duplicates drop cpsidp year month yrimmig_alt if _merge==1, force
duplicates drop cpsidp year month yrimmig_est if _merge==3, force

gen yrimmig_tot = yrimmig_alt if _merge==1
replace yrimmig_tot = yrimmig_est if _merge==3
replace yrimmig_tot = year-time_in_US if mi(yrimmig_tot) & _merge==1

replace time_weight_0 = 0 if _merge==3
replace time_weight_A = 0 if _merge==3
replace time_weight_B = 0 if _merge==3
replace time_weight_C0 = time_weight_C if _merge==3

drop time_weight_C yrimmig_alt yrimmig_est _merge
rename time_weight_C0 time_weight_C
rename yrimmig_tot yrimmig_est

replace time_in_US = year - yrimmig_est

tempfile first_last_fixed
save "`first_last_fixed'"

use "`clean_so_far'", clear
append using "`first_last_fixed'"  // 10715567
sort cpsidp year month yrimmig_est
replace yrimmig_est = . if time_in_US==30 // had to break this in lines above, this refixes

** test! **
drop sum_C min_C
bys cpsidp year month: egen sum_C=sum(time_weight_C)
bys cpsidp: egen min_C = min(sum_C)

*browse if cpsidp==20141005524101 // e.g., of a problematic case
drop _merge anyC sum_C min_C
	

** clean up, organize, create weights

order time_weight_?, last
gen monthlag = 12*(year - yrimmig_est) + month if time_in_US<30
 
gen awt0 = wtfinl*time_weight_0
gen awtA = wtfinl*time_weight_A
gen awtB = wtfinl*time_weight_B
gen awtC = wtfinl*time_weight_C

*drop time_weight_? wtfinl

** Save
compress
save $dta/tmp/cps_imm_base.dta, replace
clear

rm $dta/tmp/tmp_cps_imm_0.dta
rm $dta/tmp/tmp_cps_imm_A.dta
rm $dta/tmp/tmp_cps_imm_B.dta
rm $dta/tmp/tmp_cps_imm_C.dta



