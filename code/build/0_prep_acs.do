use "$dta/inputs/ACS/$acs.dta", clear

gen int time_in_US = year - yrimmig if yrimmig!=0
replace time_in_US=30 if inrange(time_in_US, 30, 99)
replace yrimmig = year-time_in_US if time_in_US==30 

drop if yrimmig==0 
drop if bpl < 150

collapse (rawsum) pop=perwt , by(year yrimmig time_in_US)
drop if yrimmig>year

preserve 
	rename pop popacs
	save "$dta/tmp/pop_yr_time_acs.dta", replace		
restore

preserve 
	collapse (rawsum) pop, by(year)
	rename pop popacs
	save "$dta/tmp/pop_acs.dta", replace	
restore
