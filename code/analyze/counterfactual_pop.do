use "./tmp/cps_nonresp_adj.dta", clear

tempfile nr2025 nr2026 nr2027 nrall
keep if year==2024
replace year=2025
save "`nr2025'"
replace year=2026
save "`nr2026'"
replace year=2027
save "`nr2027'"

use "./tmp/cps_nonresp_adj.dta", clear
append using "`nr2025'"
append using "`nr2026'"
append using "`nr2027'"
save "`nrall'"

clear

set obs 31
gen time_in_US = _n-1

cross using "./tmp/cbo_netimmit.dta"
drop year

gen year = time_in_US + yrimmig_est

*reg adjust is the way to go, reg+cbo is doublecount
*but CBO numbers already account for undercount

*need estimate under 16
* Cohort in Year after Timeinus
* Baseline w/o Shock:	 	1.11m*share_over_16_{t}*emppoprate_{t}
* Baseline w Shock:	 		CBO_c*share_over_16_{t}*emppoprate_{t}
* Baseline w show up: 		CBO_c*share_over_16_{t}*emppoprate_{t}*reportadj
* alt empoprate

* make baseline CBO numbers
gen CBO_no_shock = CBO_net_immig
replace CBO_no_shock = min(CBO_net_immig, 1.105985) if inrange(yrimmig_est, 2020, 2027)

* make share over 16
gen share_over_16 = 0.79 if inrange(time_in_US, 0, 2)
replace share_over_16 = min(1, 0.79+ 0.21*(time_in_US-2)/15) if mi(share_over_16)

* merge in epop as function of time in US
merge m:1 time_in_US using "./final/epop_timeinUSy.dta"
drop _merge

* merge cbo adj
merge m:1 year time_in_US using "`nrall'"
drop if _merge==2
drop _merge

* merge in reg adjusted weights
merge m:1 time_in_US yrimmig_est using "./tmp/adjustment_reg.dta"

drop adjustment adjustment_capped
*replace yrimm_adj = . if yrimmig_est==2023

egen constant_temp = mean(constant)
bys time_in_US: egen timeUS_temp = mean(timeUS_adj)

gen yrimm_temp = min(yrimmig_est, 2024)
bys yrimm_temp: egen yradj_temp = mean(yrimm_adj)

replace constant = constant_temp if mi(constant)
replace timeUS_adj = timeUS_temp if mi(timeUS_adj)
replace yrimm_adj = yradj_temp if mi(yrimm_adj)

drop if _merge==2
drop _merge *_temp

gen adjustment = min(constant+timeUS_adj+yrimm_adj, 1)

** Create populations

gen r_epop_awt_hiemp = min(r_epop_awt1_m+0.08, 0.7)

gen emp_pop_baseline = CBO_no_shock*share_over_16*r_epop_awt1_m
gen emp_pop_shock = CBO_net_immig*share_over_16*r_epop_awt1_m
gen emp_pop_shock_indata = CBO_net_immig*share_over_16*r_epop_awt1_m*adjustment
gen emp_pop_shock_indata7 = CBO_net_immig*share_over_16*r_epop_awt7_m*adjustment*nonresp_adj
gen emp_pop_shock_hiemp = CBO_net_immig*share_over_16*r_epop_awt_hiemp
gen emp_pop_shock_hiemp_indata = CBO_net_immig*share_over_16*r_epop_awt_hiemp*adjustment
gen emp_pop_shock_hiemp_indata7 = CBO_net_immig*share_over_16*r_epop_awt_hiemp*adjustment*nonresp_adj
gen underreport = emp_pop_shock-emp_pop_shock_indata
gen underreport_hiemp = emp_pop_shock_hiemp-emp_pop_shock_hiemp_indata
gen underreport_hiemp7 = emp_pop_shock_hiemp-emp_pop_shock_hiemp_indata7

keep if year>=2020 & yrimmig_est>=2020

sort yrimmig_est time_in_US

collapse (sum) emp_pop_baseline emp_pop_shoc* underrepor*, by(year)

keep if year<=2027
tsset year

twoway (line emp_pop_baseline year, lp(solid) lc(black)) || ///
		(line emp_pop_shock year, lp(solid) lc(blue)) || ///
		(line emp_pop_shock_hiemp year, lp(solid) lc(red)) || ///
		(line emp_pop_shock_indata year, lp(solid) lc(blue%30)) || ///
		(line emp_pop_shock_hiemp_indata year, lp(solid) lc(red%30)) || ///
		(line emp_pop_shock_hiemp_indata7 year, lp(solid) lc(orange%30)), ///
		legend(pos(6) row(2) order(1 "Baseline Immigration" 2 "CBO Immigration" 3 "CBO Immigration (high EPOP)")) ///
		ytitle("Foreign-Born Workers Entering US" "in 2020 or later (cum., millions)") xtitle("Year (est. December)") ///
		xsc(range(2020 2027)) xlab(2020(1)2027)

graph export "./graphs/popshock.png", replace	

twoway (line underreport year, lp(solid) lc(blue)) || ///
		(line underreport_hiemp year, lp(solid) lc(red)) || ///
		(line underreport_hiemp7 year, lp(solid) lc(orange)), ///
		legend(pos(6) row(2) order(1 "Underreported" 2 "Underreported (high EPOP)" 3 "Underreported (high EPOP, low response)")) ///
		ytitle("Underreported Foreign-Born Workers" " Entering US in 2020 or later (cum., millions)") xtitle("Year (est. December)") ///
		xsc(range(2020 2027)) xlab(2020(1)2027)

graph export "./graphs/popshock_underreport.png", replace	
	
//
// tsline emp_pop_baseline emp_pop_shock emp_pop_shock_indata emp_pop_shock_indata7 emp_pop_shock_hiemp emp_pop_shock_hiemp_indata if year<=2027, ///
// 	legend(row(2) order(1 "Baseline Immigration" 2 "CBO Immigration" 3 "CBO Immigration Visible in CPS")) ///
// 	ytitle("Foreign-Born Workers Entering US in 2020 or later" "(cumulative, millions)") xtitle("Year (March ASEC)") ///
// 	xsc(range(2020 2027)) xlab(2020(1)2027)
//	
// tsline emp_pop_shock emp_pop_shock_indata emp_pop_shock_indata7 if year<=2027, ///
// 	legend(row(2) order(1 "CBO Immigration" 2 "CBO Immigration Visible in CPS" 3 "CBO Immigration Visible in CPS")) ///
// 	ytitle("Foreign-Born Workers Entering US in 2020 or later" "(cumulative, millions)") xtitle("Year (March ASEC)") ///
// 	xsc(range(2020 2027)) xlab(2020(1)2027)
//	
//	
// tsline underreport underreport_hiemp if year<=2027, ///
// 	legend(row(2) order(1 "Underreported Foreign-Born Workers" 2 "Underreported Foreign-Born Workers, Hi Emp")) ///
// 	ytitle("Foreign-Born Workers Entering US in 2020 or later" "(cumulative, millions)") xtitle("Year (March ASEC)") ///
// 	xsc(range(2020 2027)) xlab(2020(1)2027)
