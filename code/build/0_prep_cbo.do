import excel using "$dta/inputs/CBO/cbo_immig.xlsx", clear firstrow
gen yrimmig_est=year
compress
save "$dta/tmp/cbo_netimmit.dta", replace
