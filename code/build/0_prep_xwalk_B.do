** Crosswalk B: interpolate imm year from <yrimmig> + first survey period

tempfile mon msamp xwalkinp

clear
set obs 12
gen month=_n
save "`mon'"

clear
set obs 16
gen sample_month=_n
save "`msamp'"

import excel using $git/inputs/crosswalk_to_year.xlsx, clear first
save "`xwalkinp'"

keep if inrange(time_weight, 0.25, 0.35)
cross using "`mon'"
cross using "`msamp'"

gen months_diff = 12*(time_in_US)+month-sample_month+1
sort year yrimmig month sample_month  time_in_US months_diff

gen time_weight_upd = .
replace time_weight_upd = min( max(months_diff,0), 12) / (24 + month - (sample_month-1)) if inrange(time_weight, 0.33, 0.34)
replace time_weight_upd = min( max(months_diff,0), 12) / (36 + month - (sample_month-1)) if time_weight==.25

drop if time_weight_upd==0

*test
*collapse (sum) time_weight_upd, by(year yrimmig month sample_month)

drop time_weight months_diff
rename time_weight_upd time_weight

compress
save $dta/tmp/xwalkB_yrmo.dta, replace

use "`xwalkinp'"

drop if inrange(time_weight, 0.25, 0.35)

compress
save $dta/tmp/xwalkB_yryr.dta, replace

