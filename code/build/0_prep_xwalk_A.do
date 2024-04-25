** Crosswalk A: interpolate imm year from <yrimmig> + survey period

tempfile mon xwalkinp

clear
set obs 12
gen month=_n
save "`mon'"

import excel using $git/inputs/crosswalk_to_year.xlsx, clear first
save "`xwalkinp'"

keep if inrange(time_weight, 0.25, 0.35)
cross using "`mon'"

gen time_weight_upd = .
foreach n of numlist 1/12 {
	replace time_weight_upd = `n'/(`n'+24) if month==`n' & time_in_US==0 & inrange(time_weight, 0.33, 0.34)
	replace time_weight_upd = 12/(`n'+24) if month==`n' & time_in_US!=0 & inrange(time_weight, 0.33, 0.34)
	replace time_weight_upd = `n'/(`n'+36) if month==`n' & time_in_US==0 & time_weight==.25
	replace time_weight_upd = 12/(`n'+36) if month==`n' & time_in_US!=0 & time_weight==.25
}

*test
*collapse (sum) time_weight_upd, by(year yrimmig month)

drop time_weight
rename time_weight_upd time_weight

compress
save $dta/tmp/xwalkA_yrmo.dta, replace

use "`xwalkinp'"

drop if inrange(time_weight, 0.25, 0.35)

compress
save $dta/tmp/xwalkA_yryr.dta, replace

