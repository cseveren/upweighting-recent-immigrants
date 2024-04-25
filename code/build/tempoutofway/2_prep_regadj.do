use "$dta/tmp/pop_yrm_time_cps.dta", clear

* prep data; note that ypop are the yearly equivalent for year 0 of pop (upweighted to reflect a full year)
gen ypopA=.
gen ypopB=.
gen ypopC=.

foreach n of numlist 1/12 {
	replace ypopA = popA*12/`n' if monthlag==`n' & time_in_US==0
	replace ypopB = popB*12/`n' if monthlag==`n' & time_in_US==0
	replace ypopC = popC*12/`n' if monthlag==`n' & time_in_US==0
}	

replace ypopA = popA if time_in_US!=0
replace ypopB = popB if time_in_US!=0
replace ypopC = popC if time_in_US!=0

collapse (mean) pop? ypop?, by(year time_in_US yrimmig_est)


merge 1:1 year time_in_US using "$dta/tmp/pop_yr_time_acs.dta"
drop _merge yrimmig

foreach n in 0 A B C {
	gen cps`n'_v_acs = pop`n'/popacs
}
foreach n in A B C {
	gen cpsy`n'_v_acs = ypop`n'/popacs
}

sum cps?_v_acs cpsy?_v_acs if time_in_US<30

reg cpsB_v_acs i.time_in_US i.yrimmig_est, robust
regsave using "$dta/tmp/reg_adj.dta", replace

collapse (mean) cps?_v_acs cpsy?_v_acs, by(time_in_US)

twoway  (line cps0_v_acs time_in_US) || ///
		(line cpsA_v_acs time_in_US) || ///
		(line cpsB_v_acs time_in_US) || ///
		(line cpsC_v_acs time_in_US) || ///		
		(line cpsyA_v_acs time_in_US if time_in_US<=1, lc(stc2) lp(shortdash)) || ///
		(line cpsyB_v_acs time_in_US if time_in_US<=1, lc(stc3) lp(shortdash)) || ///
		(line cpsyC_v_acs time_in_US if time_in_US<=1, lc(stc4) lp(shortdash)), ///
	legend(row(1) pos(6) order(1 "Interp. 0" 2 "Interp. A" 3 "Interp. B" 4 "Interp. C")) ///
	ylab(, nogrid) xlab(, nogrid) ///
	xtitle("Time in US (Years)") ytitle("Average Ratio of Cohort Pop. in CPS to ACS") ///
	yline(1.0, lc(gs11))  
	
graph export $git/results/cps_v_acs.png, replace	


clear
