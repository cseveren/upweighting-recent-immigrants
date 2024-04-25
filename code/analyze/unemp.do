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
keep if labforce==2


* unemployed
foreach v of varlist awt* {
	gen 	unemp_`v' = `v'*(1-inlist(empstat, 10, 12))
}

gcollapse (rawsum) awt?_m unemp_awt?_m, by(year month yrmo)
tsset yrmo


foreach v of varlist awt* {
	gen 	ur_`v' = 100 * unemp_`v'/`v'
}


foreach n of numlist 1/3 {
	gen diff`n' = ur_awt`n'-ur_awtB
}

do "$git/code/build/lab_pops.do"

tsline diff*, legend(row(1)) ylab(, nogrid) xlab(, nogrid) yline(0.0) ///
	ytitle("Adjustment to Headline Unemp Rate") xtitle("") lc(stc2 stc3 stc4)
	
graph export $git/results/alt_ur.png, replace	
