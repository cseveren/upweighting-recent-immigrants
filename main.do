** Set relative paths **
global locgit "/Users/yggdrasil/Documents/GitHub"
global locdta "/Users/yggdrasil/Dropbox/Data_Projects"
global git "${locgit}/upweighting-recent-immigrants"
global dta "${locdta}/UpweightingRecentImmigrants"

** Set data abstract names **
global cps "cps_00016" // must match your abstract name
global acs "usa_00046" // must match your abstract name
global nonresp "SeriesReport-20240911113044_c733bd.xlsx" // these will changed if updated
global cpsces "SeriesReport-20240911122828_9936a0.xlsx" // these will changed if updated
global maxyear = 2024

********
** Building CPS data including year of immigration imputation **

do ${git}/code/build/0_prep_xwalk_0.do // prepares xwalk for interp method 0
do ${git}/code/build/0_prep_xwalk_A.do // prepares xwalk for interp method A
do ${git}/code/build/0_prep_xwalk_B.do // prepares xwalk for interp methods B and C

do ${git}/code/build/0_prep_cps.do // all methods

// CHECK THIS EVERY TIME! ENSURE THAT IPUMS HAS NOT CHANGED
// None of the output values should be 0
use $dta/tmp/cps_imm_base.dta
tab time_in_US year 
tab time_in_US year [aw=awt0] 
tab time_in_US year [aw=awtC] 

** Continue CPS Collapse
do ${git}/code/build/0_collapse_cps.do

** Other Data Prep
do ${git}/code/build/0_prep_acs.do
do ${git}/code/build/0_prep_nonresponse.do
do ${git}/code/build/0_prep_cbo.do


** Checking Population Preps/Making Adjustments
do ${git}/code/build/1_popsh_xwalk_month.do		// Figures 1 and 2
do ${git}/code/build/1_make_delayadj.do			
do ${git}/code/build/1_popsh_acs.do				// Figure A1

do ${git}/code/build/9_adjust_cps.do // calls lab_pops.do

********
** Analysis (all call lab_pops.do)

do ${git}/code/analyze/compare_cohort_sizes.do 	// recent imm cohort size, Figure 3
												// + est underreporting, Figure 4
												// + Figure B1

do ${git}/code/analyze/unemp.do 				// Panel in Figure 5
do ${git}/code/analyze/lfpr.do 					// Panel in Figure 5
do ${git}/code/analyze/epop.do 					// Panel in Figure 5
												
do ${git}/code/analyze/compare_ces_cps.do		// Both penals in Figure 6
do ${git}/code/analyze/assimilation_check.do 	// cohort averages over time, Figure 7
do ${git}/code/analyze/epop_dyn.do 				// imm v native EPOP, Figure B2


* files to delete (if desired)
rm $dta/tmp/cps_nonimm_base.dta
rm $dta/tmp/cps_imm_base.dta
rm $dta/tmp/pop_yrm_time_cps.dta

clear


