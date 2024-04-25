** Basic crosswalk interpolating imm year only from <yrimmig>

import excel using $git/inputs/crosswalk_to_year.xlsx, clear first

preserve // test weights
	collapse (sum) time_weight, by(year yrimmig)
	sum time_weight
restore
	
compress
save $dta/tmp/xwalk0.dta, replace
