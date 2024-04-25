
use "$dta/tmp/reg_adj.dta", clear

** basic prep
split var, p(.)
destring var1, i("b" "_cons") replace
gen time_in_US = var1 if var2=="time_in_US"
gen yrimmig = var1 if var2=="yrimmig_est"
replace yrimmig=9999 if var=="_cons"

tempfile maindata
save "`maindata'"

** coef prep
use "`maindata'"
keep if var2=="time_in_US"
keep coef time_in_US
rename coef timeUS_adj

tempfile tadj
save "`tadj'"

use "`maindata'"
keep if var2=="yrimmig_est"
keep coef yrimmig
rename coef yrimm_adj
count
set obs `=r(N)+2'
replace yrimmig=2023 in `=r(N)+1'
replace yrimmig=2024 in `=r(N)+2'
replace yrimm_adj = yrimm_adj[_n-1] if yrimmig==2023
replace yrimm_adj = yrimm_adj[_n-1] if yrimmig==2024

tempfile yadj
save "`yadj'"

** cross/crosswalk prep
use "`maindata'"

keep yrimmig coef
drop if mi(yrimmig)
count
set obs `=r(N)+2'
replace yrimmig=2023 in `=r(N)+1'
replace yrimmig=2024 in `=r(N)+2'
gen constantt = coef if yrimmig==9999
egen constant = max(constant)
drop constantt coef
drop if yrimmig==9999
tempfile yri
save "`yri'"

use "`maindata'"
keep time_in_US
drop if mi(time_in_US)

cross using "`yri'"

merge m:1 time_in_US using "`tadj'"
drop _merge

merge m:1 yrimmig using "`yadj'"
drop _merge 

** clean
drop if yrimmig+time_in_US>2024
sort yrimmig time_in_US

gen adjustment = constant + timeUS_adj + yrimm_adj
gen adjustment_capped = min(adjustment, 1)

sum adjustment, d
sum adjustment_capped, d
rename yrimmig yrimmig_est

scatter adjustment_capped time_in_US, ysc(range(0 1)) ylab(0(0.2)1, nogrid) xlab(, nogrid) ///
	xtitle("Time in US") ytitle("Time in US Adjustment") ///
	title("Time-in-US Adjustment Factor, CPS vs ACS '00-'22", si(medsmall)) ///
	yline(1)
graph export "$git/results/adjc_timeUS.png", replace

scatter adjustment_capped yrimmig_est, ysc(range(0 1)) ylab(0(0.2)1, nogrid) xlab(, nogrid) ///
	xtitle("Year of Immigration") ytitle("Year of Immigration Adjustment") ///
	title("Year-of-Immigration Adjustment Factor, CPS vs ACS '00-'22", si(medsmall)) ///
	yline(1)
graph export "$git/results/adjc_yearimm.png", replace

scatter adjustment time_in_US, ylab(, nogrid) xlab(, nogrid) ///
	xtitle("Time in US") ytitle("Time in US Adjustment") ///
	title("Time-in-US Adjustment Factor, CPS vs ACS '00-'22", si(medsmall)) ///
	yline(1)
graph export "$git/results/adju_timeUS.png", replace

scatter adjustment yrimmig_est, ylab(, nogrid)  xlab(, nogrid) ///
	xtitle("Year of Immigration") ytitle("Year of Immigration Adjustment") ///
	title("Year-of-Immigration Adjustment Factor, CPS vs ACS '00-'22", si(medsmall)) ///
	yline(1)
graph export "$git/results/adju_yearimm.png", replace

compress

save "$git/adjustments/adjustment_reg.dta", replace
export delim using "$git/adjustments/adjustment_reg.csv", replace
clear
