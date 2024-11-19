** make analog graph of Figure 3, for ACS (Appendix)
use "$dta/tmp/pop_yr_time_acs.dta", clear

bys yrimmig: egen double maxpop = max(pop) 
gen indmax = (pop==maxpop) 
drop if yrimmig<2000 | yrimmig==.
gen shpop = pop/maxpop

sort yrimmig time_in_US
*line shpop time_in_US if yrimmig==2008

collapse (mean) shpop if yrimmig<=2019 [aw=maxpop], by(time_in_US)

line shpop time_in_US, legend(off) ///
	ysc(range(0 1)) ylab(0(0.2)1, nogrid) xlab(, nogrid) ///
	xtitle("Years Since Start of Year of Immigration") ytitle("Ave. Share of Max Cohort Pop.") ///
	title("Share of Maximum Cohort Population in ACS '00-'19", si(medsmall)) ///
	yline(1.0, lc(gs11))
	
graph export $git/results/cohest_acs_ave.pdf, replace	
graph export $git/results/cohest_acs_ave.png, replace	

clear
