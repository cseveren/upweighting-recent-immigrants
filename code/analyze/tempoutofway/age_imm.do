use  "./final/cps_reweighted.dta", clear
gen age16p = age>=16
gen cnip = !inlist(empstat, 0, 1)


preserve
	collapse (mean) age16p cnip [aw=awt1_m], by(time_in_US)
	
	line age16p time_in_US, xtitle("Years in US") ytitle("Prob of Being Aged 16+")
	graph export "./graphs/age_timeinUS.png", replace
	
	*line cnip time_in_US, xtitle("Years in US") ytitle("Prob of Being in Civ Non-Inst Pop")
	
restore
//
// collapse (mean) age16p [aw=awt], by(year time_in_US yrimmig_est)
//
// drop if time_in_US>=18
// reg age16p i.yrimmig_est i.time_in_US
//
// reg age16p i.yrimmig_est i.time_in_US if year>2010
