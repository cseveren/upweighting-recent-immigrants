***********************
** make delay adjust **

use "$dta/tmp/cps_shares_over_time.dta", clear

** shpop and shypop based on shares, adj based on regression adjustment
foreach v in A B C {
	replace shypop`v' = shpop`v' if mi(shypop`v')
}

foreach v of varlist shpop0-shypopC {
	* scale so max is 1
	sum `v'
	local pmax = r(max)
	gen `v'_adj = `v'/`pmax'
	
	* make everything following reach 1 equal to 1
	gen `v'_time_loc = (`v'_adj==1)
	gen `v'_timeml = monthlag if `v'_time_loc==1
	sum `v'_timeml
	replace `v'_adj=1 if monthlag>`r(max)'
	
	* additional upweighting to shift level up at 1 at 13 months
	gen `v'_decay_period = `r(max)' - 12
	gen temp_extra_upweight = 1 if monthlag==`r(max)'
	replace temp_extra_upweight = 1/`pmax' if inrange(monthlag, 1, 12)

	ipolate temp_extra_upweight monthlag, gen(`v'_extra_upweight)
	
	gen `v'_adj2 = `v'_adj/`v'_extra_upweight
	replace `v'_adj2=1 if mi(`v'_adj2)
	drop temp_extra_upweight
}

drop shpop0-shypopC *_time_loc *_timeml *_decay_period *_extra_upweight

foreach v of varlist adj0-adjyC {
	gen `v'_time_loc = (`v'==1)
	gen `v'_timeml = monthlag if `v'_time_loc==1
	sum `v'_timeml
	local tmax = `r(mean)'

	gen `v'_temp = `v' if inrange(monthlag, `tmax', 120)
	ipolate `v'_temp monthlag if inrange(monthlag, 13, 120), gen(`v'_temp2) epolate
	
	sum `v'_temp2
	replace `v'_temp2 = `r(max)' if inrange(monthlag, 1, 12)
	gen `v'_xtra = `v'/`v'_temp2 if inrange(monthlag, 1, `tmax')
	replace `v'=1 if monthlag>`tmax' 
	replace `v'_xtra=1 if monthlag>`tmax'
	drop `v'_temp `v'_temp2 `v'_time_loc `v'_timeml
}

drop shpop* shypop* // keep only regression adjustments

save "$git/adjustments/delayed_take_up.dta", replace
export delim using "$git/adjustments/delayed_take_up.csv", replace


use "$git/adjustments/delayed_take_up.dta"
use "$dta/tmp/cps_shares_over_time.dta", clear
twoway (lin adjyA monthlag) (lin adjyB monthlag) (lin adjyC monthlag), xline(120)



clear
