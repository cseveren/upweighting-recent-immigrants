use $dta/tmp/pop_yrm_time_cps.dta, clear

gen ypopA=.
gen ypopB=.
gen ypopC=.

foreach n of numlist 1/12 {
	replace ypopA = popA*12/`n' if monthlag==`n' & time_in_US==0
	replace ypopB = popB*12/`n' if monthlag==`n' & time_in_US==0
	replace ypopC = popC*12/`n' if monthlag==`n' & time_in_US==0
}	
replace ypopA = popA if mi(ypopA)
replace ypopB = popB if mi(ypopB)
replace ypopC = popC if mi(ypopC)

sort year time_in_US month
sort yrimmig_est monthlag

* To estimate yearly totals that reflect the current year (immigration in year 0), I
*  first assume perfect seasonality (each month receives 1/12 of a year's immigrants),
*  and then upweight year 0 month M estimates by dividing by M/12. The variables with
*  ypop or shypop should only be used when month-specific estimates of poulation that
*  include the current years are required.

foreach v in 0 A B C {
	bys yrimmig_est: egen double maxpop`v' = max(pop`v;') 
	gen indmax`v' = (pop`v'==maxpop`v') 
	drop if yrimmig_est<1994 | yrimmig_est==.
	gen shpop`v' = pop`v'/maxpop`v'
	gen pop`v'_m = pop`v'/1000
}

foreach v in A B C {
	gen shypop`v' = ypop`v'/maxpop`v'
}

** summary tables
estpost sum monthlag if indmax0==1 & yrimmig_est<=2019, d 
esttab using "$git/results/interp0_stats.csv", cells("mean p25 p50 p75") replace

estpost sum monthlag if indmaxA==1 & yrimmig_est<=2019, d
esttab using "$git/results/interpA_stats.csv", cells("mean p25 p50 p75") replace

estpost sum monthlag if indmaxB==1 & yrimmig_est<=2019, d
esttab using "$git/results/interpB_stats.csv", cells("mean p25 p50 p75") replace

estpost sum monthlag if indmaxC==1 & yrimmig_est<=2019, d
esttab using "$git/results/interpC_stats.csv", cells("mean p25 p50 p75") replace


** make pictures
foreach yr of numlist 1994 2007 2019 2022 2023 {
twoway (line pop0_m monthlag if yrimmig_est==`yr' & monthlag<=240) || ///
		(line popA_m monthlag if yrimmig_est==`yr' & monthlag<=240) || ///
		(line popB_m monthlag if yrimmig_est==`yr' & monthlag<=240) || ///
		(line popC_m monthlag if yrimmig_est==`yr' & monthlag<=240), ///
	legend(row(1) pos(6) order(1 "Interp. 0" 2 "Interp. A" 3 "Interp. B" 4 "Interp. C")) ///
	ylab(, nogrid) xlab(0(24)240, nogrid) ///
	xtitle("Months Since Start of `yr'") ytitle("Pop. of `yr' Cohort in CPS (000s)") ///
	yline(0.0, lc(gs11)) xline(12, lc(gs14) lp(solid) noextend) 
	
graph export $git/results/cohest_popm_`yr'.pdf, replace
graph export $git/results/cohest_popm_`yr'.png, replace
}

** Experimentation Zone
// local yr 1994
// twoway (line pop0_m monthlag if yrimmig_est==`yr') || ///
// 		(line popA_m monthlag if yrimmig_est==`yr') || ///
// 		(line popB_m monthlag if yrimmig_est==`yr') || ///
// 		(line popC_m monthlag if yrimmig_est==`yr'), ///
// 	legend(row(1) pos(6) order(1 "Interp. 0" 2 "Interp. A" 3 "Interp. B" 4 "Interp. C")) ///
// 	ylab(, nogrid) xlab(0(24)240, nogrid) xsc(range(0 240)) ///
// 	xtitle("Months Since Start of `yr'") ytitle("Pop. of `yr' Cohort in CPS (000s)") ///
// 	yline(0.0, lc(gs11)) xline(12, lc(gs14) lp(solid) noextend) 
//
// twoway (line shpop0 monthlag if yrimmig_est==`yr') || ///
// 		(line shpopA monthlag if yrimmig_est==`yr') || ///
// 		(line shpopB monthlag if yrimmig_est==`yr') || ///
// 		(line shpopC monthlag if yrimmig_est==`yr'), ///
// 	legend(row(1) pos(6) order(1 "Interp. 0" 2 "Interp. A" 3 "Interp. B" 4 "Interp. C")) ///
// 	ysc(range(0 1)) ylab(0(0.2)1, nogrid) xlab(0(24)360, nogrid) ///
// 	xtitle("Months Since Start of `yr'") ytitle("Share of Max `yr' Cohort Pop. in CPS") ///
// 	yline(1.0, lc(gs11)) xline(12, lc(gs14) lp(solid) noextend) 


** New Method

foreach v of varlist pop0 popA popB popC ypopA ypopB ypopC {
	gen ln`v' = ln(`v')
}

reghdfe lnpop0 ib60.monthlag if yrimmig_est<=2019, a(yrimmig_est)
predict adj_t0, xb
gen adj0 = exp(adj_t0 - _b[_cons])

reghdfe lnpopA ib60.monthlag if yrimmig_est<=2019, a(yrimmig_est)
predict adj_tA, xb
gen adjA = exp(adj_tA - _b[_cons])

reghdfe lnpopB ib26.monthlag if yrimmig_est<=2019, a(yrimmig_est)
predict adj_tB, xb
gen adjB = exp(adj_tB - _b[_cons])

reghdfe lnpopC ib27.monthlag if yrimmig_est<=2019, a(yrimmig_est)
predict adj_tC, xb
gen adjC = exp(adj_tC - _b[_cons])

reghdfe lnypopA ib60.monthlag if yrimmig_est<=2019, a(yrimmig_est)
predict adjy_tA, xb
gen adjyA = exp(adjy_tA - _b[_cons])

reghdfe lnypopB ib26.monthlag if yrimmig_est<=2019, a(yrimmig_est)
predict adjy_tB, xb
gen adjyB = exp(adjy_tB - _b[_cons])

reghdfe lnypopC ib27.monthlag if yrimmig_est<=2019, a(yrimmig_est)
predict adjy_tC, xb
gen adjyC = exp(adjy_tC - _b[_cons])

drop adj_t? adjy_t?
*coefplot, keep(*.monthlag) vertical

sort yrimmig_est monthlag


preserve
	collapse (mean) shpop? shypop? if inrange(yrimmig_est, 0, 2019), by(monthlag)

twoway (line shpop0 monthlag if monthlag<=240) || ///
		(line shpopA monthlag if monthlag<=240) || ///
		(line shpopB monthlag if monthlag<=240) || ///
		(line shpopC monthlag if monthlag<=240), ///
	legend(row(1) pos(6) order(1 "Interp. 0" 2 "Interp. A" 3 "Interp. B" 4 "Interp. C")) ///
	ysc(range(0 1)) ylab(0(0.2)1, nogrid) xlab(0(24)240, nogrid) ///
	xtitle("Months Since Start of Year of Immigration") ytitle("Ave. Share of Max Cohort Pop.") ///
	title("Share of Maximum Cohort Population in Basic CPS '94-'19", si(medsmall)) ///
	yline(1.0, lc(gs11)) xline(12, lc(gs14) lp(solid) noextend) 
restore


collapse (mean) shpop? shypop? adj* if inrange(yrimmig_est, 0, 2019), by(monthlag)

twoway (line shpop0 monthlag if monthlag<=240) || ///
		(line shpopA monthlag if monthlag<=240) || ///
		(line shpopB monthlag if monthlag<=240) || ///
		(line shpopC monthlag if monthlag<=240), ///
	legend(row(1) pos(6) order(1 "Interp. 0" 2 "Interp. A" 3 "Interp. B" 4 "Interp. C")) ///
	ysc(range(0 1)) ylab(0(0.2)1, nogrid) xlab(0(24)240, nogrid) ///
	xtitle("Months Since Start of Year of Immigration") ytitle("Ave. Share of Max Cohort Pop.") ///
	title("Share of Maximum Cohort Population in Basic CPS '94-'19", si(medsmall)) ///
	yline(1.0, lc(gs11)) xline(12, lc(gs14) lp(solid) noextend) 



twoway (line adj0 monthlag if monthlag<=240) || ///
		(line adjA monthlag if monthlag<=240) || ///
		(line adjB monthlag if monthlag<=240) || ///
		(line adjC monthlag if monthlag<=240), ///
	legend(row(1) pos(6) order(1 "Interp. 0" 2 "Interp. A" 3 "Interp. B" 4 "Interp. C")) ///
	ysc(range(0 1)) ylab(0(0.2)1, nogrid) xlab(0(24)240, nogrid) ///
	xtitle("Months Since Start of Year of Immigration") ytitle("Estimated Share of Max Cohort Pop.") ///
	title("Share of Maximum Cohort Population in Basic CPS '94-'19", si(medsmall)) ///
	yline(1.0, lc(gs11)) xline(12, lc(gs14) lp(solid) noextend) yline(1.0, lc(gs11)) xline(120, lc(gs14) lp(dashdot) noextend)

graph export $git/results/cohest_shrm_ave.png, replace	
graph export $git/results/cohest_shrm_ave.pdf, replace	


// twoway (line shpop0 monthlag if monthlag<=12) || ///
// 		(line shypopA monthlag if monthlag<=240) || ///
// 		(line shypopB monthlag if monthlag<=240) || ///
// 		(line shypopC monthlag if monthlag<=240), ///
// 	legend(row(1) pos(6) order(1 "Interp. 0" 2 "Interp. A" 3 "Interp. B" 4 "Interp. C")) ///
// 	ysc(range(0 1)) ylab(0(0.2)1, nogrid) xlab(0(24)240, nogrid) ///
// 	xtitle("Months Since Start of Year of Immigration") ytitle("Ave. Share of Max Cohort Pop.") ///
// 	title("Share of Maximum Cohort Population in Basic CPS '94-'19", si(medsmall)) ///
// 	yline(1.0, lc(gs11)) xline(12, lc(gs14) lp(solid) noextend) 

save "$dta/tmp/cps_shares_over_time.dta", replace
	

