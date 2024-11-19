****************************
** Epop by time in US

** Epop non-imm pop
use "$dta/inputs/CPS_Basic/$cps.dta", clear
keep if yrimmig==0 | bpl < 14999

keep if age>=16
drop if empstat==1
gen emp_standard = inlist(emp, 10, 12)

sum emp_standard [aw=wtfinl]
local nat_born_mean = `r(mean)'

clear

** Epop by time in US, average
use "$dta/final/cps_reweighted.dta", clear

keep if age>=16
drop if empstat==1
gen emp_standard = inlist(emp, 10, 12)

foreach v of varlist awtB_m awt1_m awt2_m {
	gen epop_`v' = `v' * emp_standard
}

collapse (rawsum) awt* epop_*, by(monthlag time_in_US)

foreach v of varlist awtB_m awt1_m awt2_m {
	gen r_epop_`v' = epop_`v'/`v' 
}
*twoway (line r_epop_awt4_m monthlag) || (line r_epop_awt4_y monthlag)

twoway (line r_epop_awt1_m monthlag), ///
		yline(`nat_born_mean') xtitle("Months (interpolated) in US") ///
		ytitle("Emp/Pop (16+)") xlab(, nogrid) ylab(, nogrid) ///
		text(0.59 300 "Native-born Emp/Pop (16+)") ///
		text(0.695 75 "Foriegn-born Emp/Pop (16+)", color(midblue))

graph export "$git/results/emppop_timeinUSm.pdf", replace	
graph export "$git/results/emppop_timeinUSm.png", replace	


clear






