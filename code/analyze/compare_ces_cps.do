** Create Adjusted CPS
use "$dta/inputs/CPS_Basic/$cps.dta", clear
keep if yrimmig==0 | bpl < 14999
keep if age>=15

append using "$dta/final/cps_reweighted.dta"
keep if age>=15

foreach v of varlist awt* {
	replace `v' = wtfinl if mi(`v')
}

drop wtfinl

gen yrmo = ym(year, month)
format yrmo %tm

** Now Use as Normal, but with awt or awt? instead of wtfinl

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
drop emp_awt?_y 
format emp_aw*  %9.0f
tsset yrmo


save "$dta/final/ces_v_cps.dta", replace

// gen empgrowth_B = S12.emp_awtB_m/12
// gen empgrowth_1 = S12.emp_awt1_m/12
// gen empgrowth_2 = S12.emp_awt2_m/12
// gen empgrowth_3 = S12.emp_awt3_m/12
// format empgr*  %9.0f
//
// gen diff1 = empgrowth_1 - empgrowth_B
// gen diff2 = empgrowth_2 - empgrowth_B
// gen diff3 = empgrowth_3 - empgrowth_B
//
// tsline diff1 diff2 diff3 
// tsline diff1 diff2 diff3 if yrmo>tm(2020m1)

*save "$dta/final/ces_v_cps.dta", replace
 
****
clear
import excel using "$dta/inputs/Adj_CPS/$cpsces", firstrow cellrange(A12)

drop if mi(Year)

rename Jan m_1
rename Feb m_2
rename Mar m_3
rename Apr m_4
rename May m_5
rename Jun m_6
rename Jul m_7
rename Aug m_8
rename Sep m_9
rename Oct m_10
rename Nov m_11
rename Dec m_12

reshape long m_, i(Year) j(Month)
rename m_ adjcps
rename Year year
rename Month month

gen yrmo = ym(year, month)
format yrmo %tm
drop if mi(yrmo)
drop if mi(adjcps)

drop year month
tempfile adj
save "`adj'"

use "$dta/final/ces_v_cps.dta", clear
merge 1:1 yrmo using "`adj'"
drop if _merge!=3

drop _merge

foreach v of varlist emp_awt* {
	replace  `v'=`v'/1000
}

*tsline emp_awtB_m adjcps

*back out seasonal adjustment
gen sa_adj = adjcps/emp_awtB_m

tsset yrmo

foreach v of varlist emp_awt*  {
	gen `v'_sa = sa_adj*`v'
	gen diff_`v'_sa = `v'_sa - adjcps
	gen grow_`v'_sa = D.`v'_sa	
}

foreach v of varlist emp_awt1_m-emp_awt4_m {
	gen diffgrow_`v'_sa = grow_`v'_sa - grow_emp_awtB_m_sa
	tssmooth ma diffgrow_`v'_sa_ma = diffgrow_`v'_sa, w(11 1)
}

do "$git/code/build/lab_pops.do"

tsline diffgrow_emp_awt1_m_sa diffgrow_emp_awt2_m_sa diffgrow_emp_awt3_m_sa if yrmo>tm(2020m1), ///
	legend(row(1)) ylab(, nogrid) xlab(, nogrid) yline(0.0) ///
	ytitle("Adjustment to Household Survey Job Growth" "(thousands of jobs)") xtitle("") lc(stc2 stc3 stc4)

graph export $git/results/cesframe_growthadj.pdf, replace	
graph export $git/results/cesframe_growthadj.png, replace	
	
tsline diffgrow_emp_awt1_m_sa_ma diffgrow_emp_awt2_m_sa_ma diffgrow_emp_awt3_m_sa_ma if yrmo>tm(1995m1), ///
	legend(row(1)) ylab(, nogrid) xlab(, nogrid) yline(0.0) ///
	ytitle("Adjustment to Household Survey Job Growth" "(12-month moving average, thousands of jobs)") xtitle("") lc(stc2 stc3 stc4)

graph export $git/results/cesframe_growthadjMA.pdf, replace	
graph export $git/results/cesframe_growthadjMA.png, replace		
	
