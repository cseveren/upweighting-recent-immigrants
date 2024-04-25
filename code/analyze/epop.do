** Create Adjusted CPS
use "$dta/inputs/CPS_Basic/$cps.dta", clear
keep if yrimmig==0 | bpl < 14999
keep if age>=16

append using "$dta/final/cps_reweighted.dta"
keep if age>=16

foreach v of varlist awt* {
	replace `v' = wtfinl if mi(`v')
}

drop wtfinl

gen yrmo = ym(year, month)
format yrmo %tm

** Coding
drop if empstat==1


* plus multiple jobholders
foreach v of varlist awt* {
	gen 	emp_`v' = `v'*(inlist(empstat, 10, 12))
}

gcollapse (rawsum) awt?_m emp_awt?_m, by(year month yrmo)
tsset yrmo

foreach v of varlist awt* {
	gen 	epop_`v' = 100*emp_`v'/`v'
}

foreach n of numlist 1/3 {
	gen diff`n' = epop_awt`n'-epop_awtB
}

do "$git/code/build/lab_pops.do"

tsline diff*, legend(row(1)) ylab(, nogrid) xlab(, nogrid) yline(0.0) ///
	ytitle("Adjustment to Headline EPOP Rate") xtitle("") lc(stc2 stc3 stc4)
	
graph export $git/results/alt_epop.png, replace	
