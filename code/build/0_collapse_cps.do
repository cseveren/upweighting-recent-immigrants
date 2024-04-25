use $dta/tmp/cps_imm_base.dta, clear

** Create additional collapse data for future use

collapse (rawsum) pop0=awt0 popA=awtA popB=awtB popC=awtC, by(year month yrimmig_est time_in_US monthlag)

format pop? %8.0f

compress
save $dta/tmp/pop_yrm_time_cps.dta, replace
