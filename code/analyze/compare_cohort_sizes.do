
** Immigrants here 0 years
use "$dta/final/pops_immcohort_time.dta", clear

collapse (mean) pop?_y, by(time_in_US yrimmig_est)

do "$git/code/build/lab_pops.do"

keep if time_in_US==0 & yrimmig_est>=2000

merge 1:1 yrimmig_est using "$dta/tmp/cbo_netimmit.dta"
drop _merge

lab var CBO_net_immig "CBO Net Imm. Est."
replace CBO_net_immig=CBO_net_immig*1000000

twoway (line popB_y yrimmig_est ) ///
		(line pop1_y yrimmig_est) ///
		(line pop2_y yrimmig_est) ///
		(line pop3_y yrimmig_est) ///
		(scatter CBO_net_immig yrimmig_est, ms(vlarge) mc(green)), ///
		legend(pos(6) row(2)) xtitle("Year of Immigration") ytitle("Immigrants here <1 year") ///
		ylab(, nogrid) xlab(, nogrid)

graph export $git/results/cohest_adj_y0.pdf, replace	
graph export $git/results/cohest_adj_y0.png, replace	
	
** Immigrants here 0-1 years
use "$dta/tmp/cbo_netimmit.dta", clear
drop year
gen time_in_US=0
tempfile cbo_0
save "`cbo_0'"

use "$dta/tmp/cbo_netimmit.dta"
drop year
gen time_in_US=1
replace yrimmig_est = yrimmig_est+1
tempfile cbo_1
save "`cbo_1'"

use "$dta/final/pops_immcohort_time.dta", clear

collapse (mean) pop?_y, by(time_in_US yrimmig_est)

keep if time_in_US<=1 & yrimmig_est>=2000

merge 1:1 yrimmig_est time_in_US using "`cbo_0'"
drop _merge
merge 1:1 yrimmig_est time_in_US using "`cbo_1'", update
drop _merge

drop if yrimmig_est==2000

collapse (sum) pop?_y CBO_net_immig, by(yrimmig_est)
do "$git/code/build/lab_pops.do"

lab var CBO_net_immig "CBO Net Imm. Est."
replace CBO_net_immig=CBO_net_immig*1000000

twoway (line popB_y yrimmig_est if yrimmig_est<=2023) ///
		(line pop1_y yrimmig_est if yrimmig_est<=2023) ///
		(line pop2_y yrimmig_est if yrimmig_est<=2023) ///
		(line pop3_y yrimmig_est if yrimmig_est<=2023) ///
		(scatter CBO_net_immig yrimmig_est, ms(vlarge) mc(green)), ///
		legend(pos(6) row(2)) xtitle("Year of Immigration") ytitle("Immigrants here <2 years") ///
		ylab(, nogrid) xlab(, nogrid)		

graph export $git/results/cohest_adj_y01.pdf, replace	
graph export $git/results/cohest_adj_y01.png, replace	
			
		
* Cumulative Flow, Monthly	// Excluded from draft

use "$dta/tmp/cbo_netimmit.dta", clear
keep if year>=2020
sort year
gen cum_CBO=sum(CBO_net_immig)
drop CBO_net_immig
rename cum_CBO CBO_net_immig
tempfile cbo_cum
save "`cbo_cum'"	

	
use "$dta/final/pops_immcohort_time.dta", clear

gen yrmo = ym(year, month)
format yrmo %tm		
collapse (sum) pop?_m if yrimmig_est>=2020 & !mi(yrimmig_est), by(yrmo year month)

do "$git/code/build/lab_pops.do"	

merge m:1 year using "`cbo_cum'"	
drop if _merge!=3
drop _merge

replace CBO_net_immig=. if month!=12
replace CBO_net_immig=CBO_net_immig*1000000

lab var CBO_net_immig "CBO Net Imm. Est."

twoway  (line popB_m yrmo) ///
		(line pop1_m yrmo) ///
		(line pop2_m yrmo) ///
		(line pop3_m yrmo) ///
		(scatter CBO_net_immig yrmo, ms(vlarge) mc(green)), ///
		legend(pos(6) row(2)) ///
		xtitle("") ytitle("Cumulative Immigration since 2020") 
		
graph export $git/results/cohest_adj_post2020.pdf, replace	
graph export $git/results/cohest_adj_post2020.png, replace	
		
** Under-reporting

use "$dta/final/pops_immcohort_time.dta", clear

gen yrmo = ym(year, month)

gen underreport1 = pop1_m - popB_m
gen underreport2 = pop2_m - popB_m
gen underreport3 = pop3_m - popB_m

collapse (sum) underreport?, by(yrmo)
format yrmo %tm		

do "$git/code/build/lab_pops.do"

twoway  (line underreport1 yrmo, lc(stc2)) ///
		(line underreport2 yrmo, lc(stc3)) ///
		(line underreport3 yrmo, lc(stc4)), ///
		legend(pos(6) row(1)) xtitle("") ytitle("Estimated CPS Underreporting of Immigrants" "(relative to Baseline Interp. B)") ///
		ylab(, nogrid) xlab(, nogrid) yline(0)	

graph export $git/results/misreport.pdf, replace	
graph export $git/results/misreport.png, replace	
clear		
