use "$dta/tmp/pop_yr_time_acs.dta", clear
 
gen month=6
tempfile acs
save "`acs'"

use "$dta/tmp/cbo_netimmit.dta", clear
gen month=12
tempfile cbo
save "`cbo'"

*use "$dta/final/pop_moyr_time_cps_wts.dta", clear
use "$dta/final/pops_immcohort_time.dta", clear

keep if inrange(year, 2000, $maxyear)

merge 1:1 year month time_in_US using "`acs'"
drop _merge yrimmig
*gen popacs0 = popacs/0.55 if time_in_US==0

merge m:1 year month using "`cbo'", keepusing(CBO_net_immig)
drop _merge
replace CBO_net_immig=. if !inlist(time_in_US, 0, .)
rename CBO_net_immig CBO_net_immig_m

// merge m:1 yrimmig using "`cbo'", keepusing(CBO_net_immig)
// rename CBO_net_immig CBO_net_immig_running
// replace CBO_net_immig_m=CBO_net_immig_running if _merge==2
// drop _merge

foreach v of varlist popB_m-popacs {
	gen `v'_m = `v'/1000000
}

replace time_in_US = 0 if mi(year) // for CBO numbers
replace year = yrimmig_est if mi(year) // for CBO numbers

// do "./lab_pops.do"
lab var popacs "ACS"

gen yrmo = ym(year, month)
format yrmo %tm

gen ratioB = popB_y/popacs 
collapse (mean) ratioB, by(time_in_US)

line ratioB time_in_US, lw(thick) lc(dknavy)

***********
** baseline data in US 0 years
twoway (line popacs yrmo if time_in_US==0, lw(thick) lc(dknavy)) || ///
		(line popB_y yrmo if time_in_US==0 & month==6, lw(thick) lc(red%40)) || ///
		(scatter CBO_net_immig_m yrmo, mc(green) msize(medlarge)), ///
		ytitle("Foreign-Born Pop in US for <1 year" "(millions)") ///
		legend(row(1) pos(6)) xlab(, nogrid) ylab(, nogrid) 

** baseline data in US 0 years
// twoway (line popacs_m year if time_in_US==0, lw(thick) lc(dknavy)) || ///
// 		(line pop_m year if time_in_US==0, lw(thick) lc(red%40)) || ///
// 		(line pop2_m year if time_in_US==0, lw(thick) lc(orange%40)) || ///
// 		(scatter CBO_net_immig_m year if time_in_US==0, mc(green) msize(medlarge)), ///
// 		ytitle("Foreign-Born Pop in US for <1 year" "(millions)") ///
// 		legend(row(1) pos(6)) xlab(, nogrid) ylab(, nogrid) 

graph export "./graphs/data_pop_0yrs.png", replace
	
	
** estimates in US 0, 1, 2 years
* in year 0, cap, uncapped make no difference
twoway (line popacs_m yrmo if time_in_US==2 & year>=2000, lw(thick) lc(dknavy)) || ///
		(line popB_y_m yrmo if time_in_US==2 & year>=2000, lw(thick) lc(red%40)) || ///
		(line pop1_y_m yrmo if time_in_US==2 & year>=2000, lp(dash)) || ///
		(line pop2_y_m yrmo if time_in_US==2 & year>=2000, lp(dash)) || ///
		(line pop3_y_m yrmo if time_in_US==2 & year>=2000, lp(dash)) || ///
		(scatter CBO_net_immig_m yrmo if time_in_US<=2 & inrange(year, 2000, 2024), mc(green) msize(medlarge)), ///
		ytitle("Foreign-Born Pop in US for <1 year" "(millions)") ///
		legend(row(3) pos(6)) xlab(,nogrid) ylab(, nogrid)
	
graph export "./graphs/estpop_0yrs_adjsingle.png", replace

twoway (line popacs0_m yrmo if time_in_US==0 & year>=2000, lw(thick) lc(dknavy)) || ///
		(line pop0_y_m yrmo if time_in_US==0 & year>=2000, lw(thick) lc(red%40)) || ///
		(line pop4_y_m yrmo if time_in_US==0 & year>=2000, lp(dash)) || ///
		(line pop7_y_m yrmo if time_in_US==0 & year>=2000, lp(dash)) || ///
		(line pop8_y_m yrmo if time_in_US==0 & year>=2000, lp(dash)) || ///
		(scatter CBO_net_immig_m yrmo if time_in_US==0 & inrange(year, 2000, 2024), mc(green) msize(medlarge)), ///
		ytitle("Foreign-Born Pop in US for <1 year" "(millions)") ///
		legend(row(3) pos(6)) xlab(,nogrid) ylab(, nogrid)
	
graph export "./graphs/estpop_0yrs_adjmulti.png", replace

twoway (line popacs_m yrmo if time_in_US==1 & year>=2000, lw(thick) lc(dknavy)) || ///
		(line pop0_y_m yrmo if time_in_US==1 & year>=2000, lw(thick) lc(red%40)) || ///
		(line pop1_y_m yrmo if time_in_US==1 & year>=2000, lp(dash)) || ///
		(line pop2_y_m yrmo if time_in_US==1 & year>=2000, lp(dash)) || ///
		(line pop3_y_m yrmo if time_in_US==1 & year>=2000, lp(dash)) || ///
		(line pop6_y_m yrmo if time_in_US==1 & year>=2000, lp(dash)), ///
		ytitle("Foreign-Born Pop in US for 1 year" "(millions)") ///
		legend(row(3) pos(6)) xlab(,nogrid) ylab(0(1)4, nogrid) 

graph export "./graphs/estpop_1yrs_adjsingle.png", replace
		
twoway (line popacs_m yrmo if time_in_US==1 & year>=2000, lw(thick) lc(dknavy)) || ///
		(line pop0_y_m yrmo if time_in_US==1 & year>=2000, lw(thick) lc(red%40)) || ///
		(line pop4_y_m yrmo if time_in_US==1 & year>=2000, lp(dash)) || ///
		(line pop5_y_m yrmo if time_in_US==1 & year>=2000, lp(dash)) || ///
		(line pop7_y_m yrmo if time_in_US==1 & year>=2000, lp(dash)) || ///
		(line pop8_y_m yrmo if time_in_US==1 & year>=2000, lp(dash)) || ///
		(line pop9_y_m yrmo if time_in_US==1 & year>=2000, lp(dash)), ///
		ytitle("Foreign-Born Pop in US for 1 year" "(millions)") ///
		legend(row(3) pos(6)) xlab(,nogrid) ylab(0(1)4, nogrid) 
		
graph export "./graphs/estpop_1yrs_adjmulti.png", replace

twoway (line popacs_m yrmo if time_in_US==2 & year>=2000, lw(thick) lc(dknavy)) || ///
		(line pop0_y_m yrmo if time_in_US==2 & year>=2000, lw(thick) lc(red%40)) || ///
		(line pop1_y_m yrmo if time_in_US==2 & year>=2000, lp(dash)) || ///
		(line pop2_y_m yrmo if time_in_US==2 & year>=2000, lp(dash)) || ///
		(line pop3_y_m yrmo if time_in_US==2 & year>=2000, lp(dash)) || ///
		(line pop6_y_m yrmo if time_in_US==2 & year>=2000, lp(dash)), ///
		ytitle("Foreign-Born Pop in US for 2 years" "(millions)") ///
		legend(row(3) pos(6)) xlab(,nogrid) ylab(0(1)4, nogrid) 

graph export "./graphs/estpop_2yrs_adjsingle.png", replace
		
twoway (line popacs_m yrmo if time_in_US==2 & year>=2000, lw(thick) lc(dknavy)) || ///
		(line pop0_y_m yrmo if time_in_US==2 & year>=2000, lw(thick) lc(red%40)) || ///
		(line pop4_y_m yrmo if time_in_US==2 & year>=2000, lp(dash)) || ///
		(line pop5_y_m yrmo if time_in_US==2 & year>=2000, lp(dash)) || ///
		(line pop7_y_m yrmo if time_in_US==2 & year>=2000, lp(dash)) || ///
		(line pop8_y_m yrmo if time_in_US==2 & year>=2000, lp(dash)) || ///
		(line pop9_y_m yrmo if time_in_US==2 & year>=2000, lp(dash)), ///
		ytitle("Foreign-Born Pop in US for 2 years" "(millions)") ///
		legend(row(3) pos(6)) xlab(,nogrid) ylab(0(1)4, nogrid) 
		
graph export "./graphs/estpop_2yrs_adjmulti.png", replace


** estimates in US Total
replace popacs0_m = popacs_m if mi(popacs0_m)
collapse (rawsum) pop?_m_m popacs0_m, by(yrmo)	

replace popacs0 = . if popacs==0
drop if yrmo>=tm(2024m12)
drop if yrmo<tm(2000m1)

do "./lab_pops.do"
lab var popacs0_m "ACS/0.55"


twoway (line popacs0_m yrmo, lw(thick) lc(dknavy)) || ///
		(line pop0_m_m yrmo, lw(thick) lc(red%40)) || ///
		(line pop1_m_m yrmo, lp(dash)) || ///
		(line pop2_m_m yrmo, lp(dash)) || ///
		(line pop3_m_m yrmo, lp(dash)) || ///
		(line pop6_m_m yrmo, lp(dash)), ///
		ytitle("Total Foreign-Born Pop in US" "(millions)") ///
		legend(row(3) pos(6)) xlab(, nogrid) ylab(, nogrid) 

graph export "./graphs/estpop_total_adjsingle.png", replace	

twoway (line popacs0_m yrmo, lw(thick) lc(dknavy)) || ///
		(line pop0_m_m yrmo, lw(thick) lc(red%40)) || ///
		(line pop4_m_m yrmo, lp(dash)) || ///
		(line pop5_m_m yrmo, lp(dash)) || ///
		(line pop7_m_m yrmo, lp(dash)) || ///
		(line pop8_m_m yrmo, lp(dash)) || ///
		(line pop9_m_m yrmo, lp(dash)), ///
		ytitle("Total Foreign-Born Pop in US" "(millions)") ///
		legend(row(3) pos(6)) xlab(, nogrid) ylab(, nogrid) 

graph export "./graphs/estpop_total_adjmulti.png", replace	

keep if yrmo>=tm(2010m1)

twoway (line popacs0_m yrmo, lw(thick) lc(dknavy)) || ///
		(line pop0_m_m yrmo, lw(thick) lc(red%40)) || ///
		(line pop1_m_m yrmo, lp(dash)) || ///
		(line pop2_m_m yrmo, lp(dash)) || ///
		(line pop3_m_m yrmo, lp(dash)) || ///
		(line pop6_m_m yrmo, lp(dash)), ///
		ytitle("Total Foreign-Born Pop in US" "(millions)") ///
		legend(row(3) pos(6)) xlab(, nogrid) ylab(, nogrid) 

graph export "./graphs/estpop10_total_adjsingle.png", replace	

twoway (line popacs0_m yrmo, lw(thick) lc(dknavy)) || ///
		(line pop0_m_m yrmo, lw(thick) lc(red%40)) || ///
		(line pop4_m_m yrmo, lp(dash)) || ///
		(line pop5_m_m yrmo, lp(dash)) || ///
		(line pop7_m_m yrmo, lp(dash)) || ///
		(line pop8_m_m yrmo, lp(dash)) || ///
		(line pop9_m_m yrmo, lp(dash)), ///
		ytitle("Total Foreign-Born Pop in US" "(millions)") ///
		legend(row(3) pos(6)) xlab(, nogrid) ylab(, nogrid) 

graph export "./graphs/estpop_total_adjmulti.png", replace		
		
		
		