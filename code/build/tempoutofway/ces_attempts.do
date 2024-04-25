** Misreported Jobs
** Epop by time in US, average
use "$dta/final/cps_reweighted.dta", clear

keep if age>=15

gen yrmo = ym(year, month)
format yrmo %tm

** adjust to CES frame

* start with total employment, 
keep if inlist(empstat, 1, 10, 12)
* minus
* 	ag and related
drop if inrange(ind1990, 10, 30) | ind1990==32		
* 	uninc self employed 
drop if classwkr==13
* 	unpaid fam workers in fam-owned bus		
drop if classwkr==29
*	workers in private hh's
drop if ind1990==761
* 	non-ag employees on unpaid leave 
drop if uh_payabs_b2==2
* plus multiple jobholders
foreach v of varlist awt* {
	gen 	emp_`v' = `v' if numjob==0
	replace emp_`v' = 2*`v' if numjob==2
	replace emp_`v' = 3*`v' if numjob==3
	replace emp_`v' = 4*`v' if numjob==4
}

collapse (rawsum) emp_aw*, by(year month yrmo)

gen underreport1 = emp_awt1_m - emp_awtB_m
gen underreport2 = emp_awt2_m - emp_awtB_m
gen underreport3 = emp_awt3_m - emp_awtB_m
gen underreport4 = emp_awt4_m - emp_awtB_m

label var underreport1 "Delayed Take Up"
label var underreport2 "Excess Non-Resp."
label var underreport3 "ACS Align. (cap)"
label var underreport4 "ACS Align. (uncap)"

twoway  (line underreport1 yrmo, lc(stc2)) ///
		(line underreport2 yrmo, lc(stc3)) ///
		(line underreport3 yrmo, lc(stc4)) ///
		(line underreport4 yrmo, lc(stc5)), ///
		legend(pos(6) row(2)) xtitle("") ytitle("CPS Misreporting of Jobs") ///
		ylab(, nogrid) xlab(, nogrid) yline(0)	
clear		



drop emp_awt?_y 
format emp_aw*  %9.0f
tsset yrmo
