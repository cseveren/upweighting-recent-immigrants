use "$dta/tmp/cps_imm_base.dta", clear

drop time_weight_0 time_weight_A time_weight_B time_weight_C awt0 awtA awtC hwtfinl wtfinl

* To estimate yearly totals that reflect the current year (immigration in year 0), I
*  first assume perfect seasonality (each month receives 1/12 of a year's immigrants),
*  and then upweight year 0 month M estimates by dividign by M/12. The variables with
*  awt?y or awt?_y should only be used when month-specific estimates of poulation that
*  include the current years are required.

gen awtBy=.
foreach n of numlist 1/12 {
	replace awtBy = awtB*12/`n' if monthlag==`n'
}

replace awtBy = awtB if mi(awtBy)

* merge in simple decay weights
merge m:1 monthlag using "$git/adjustments/delayed_take_up.dta", keepusing(adjB adjyB adjB_xtra adjyB_xtra) //shpopB_adj shypopB_adj shpopB_adj2 shypopB_adj2) 
	// Upweight by adj? and adj?_extra to approximate monthly totals, and by adjy? and adjy?_extra
	//  to approximate yearly totals at each monthly
drop _merge   

foreach v of varlist adjB adjyB adjB_xtra adjyB_xtra {
	replace `v'=1 if time_in_US==30
}

gen awt1_m = awtB/adjyB
gen awt1_y = awtB/adjB

gen awt2_m = awtB/adjyB_xtra
gen awt2_y = awtB/adjB_xtra

* merge in CBO-non response weights
merge m:1 year month time_in_US using "$git/adjustments/nonresp_adj.dta"
drop if _merge!=3 
	// Double check this! Will only mismatch if non-response and CPS do not have same coverage
drop _merge   

gen awt3_m = awtB/nonresp_adj
gen awt3_y = awtBy/nonresp_adj

* make combination
gen awt4_m = awtB/adjyB/nonresp_adj
gen awt4_y = awtB/adjB/nonresp_adj

** rename and clean up
rename awtB awtB_m
rename awtBy awtB_y

drop  adjB adjyB adjB_xtra adjyB_xtra nonresp_adj

*use <mo> when summing immigration in a month, use <yr> when summing by year of imm
do "$git/code/build/lab_pops.do"

compress

save "$dta/final/cps_reweighted.dta", replace

collapse (rawsum) awt?_?, by(year yrimmig_est time_in_US month monthlag)
sort yrimmig_est monthlag


rename awt?_? pop?_?
do "$git/code/build/lab_pops.do"

compress
save "$dta/final/pops_immcohort_time.dta", replace
