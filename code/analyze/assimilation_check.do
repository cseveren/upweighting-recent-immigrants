use $dta/tmp/cps_imm_base.dta, clear

gen lt_coll = educ<100
gen male = sex==1
gen mexico = bpl==20000
gen age_at_imm = age - time_in_US

collapse (mean) lt_coll male mexico age age_at_imm [aw=awtB], by(yrimmig_est time_in_US year)
	
keep if inlist(yrimmig_est, 2001, 2003, 2005, 2007, 2009, 2011, 2013, 2015, 2017, 2019, 2021, 2023)		

label var lt_coll 	"Share of Imm. Cohort with Less Than College Educ."
label var male 		"Male Share of Imm. Cohort"
label var mexico 	"Share of Imm. Cohort from Mexico"
label var age 		"Average Age of Imm. Cohort"
label var age_at_imm  "Average Age at Arrival of Imm. Cohort"

foreach var of varlist lt_coll male mexico age_at_imm {

local col1 gs10
local col2 red
local col3 purple
twoway  (scatter `var' year if time_in_US==0 & yrimmig_est<2020, mc(`col1'%60)) || ///
		(line `var' year if yrimmig_est==2001, lc(`col1'%64)) || ///
		(line `var' year if yrimmig_est==2003, lc(`col1'%68)) || ///
		(line `var' year if yrimmig_est==2005, lc(`col1'%72)) || ///
		(line `var' year if yrimmig_est==2007, lc(`col1'%76)) || ///
		(line `var' year if yrimmig_est==2009, lc(`col1'%80)) || ///
		(line `var' year if yrimmig_est==2011, lc(`col1'%84)) || ///
		(line `var' year if yrimmig_est==2013, lc(`col1'%88)) || ///
		(line `var' year if yrimmig_est==2015, lc(`col1'%92)) || ///
		(line `var' year if yrimmig_est==2017, lc(`col1'%96)) || ///
		(line `var' year if yrimmig_est==2019, lc(`col1'%100)) || ///
		(scatter `var' year if time_in_US==0 & yrimmig_est==2021, mc(`col2')) || ///
		(line `var' year if yrimmig_est==2021, lc(`col2')) || ///
		(scatter `var' year if time_in_US==0 & yrimmig_est==2023, mc(`col3')) || ///
		(line `var' year if yrimmig_est==2023, lc(`col3')), ///
		legend(off) ylab(, nogrid) xlab(, nogrid) xtitle("Year")
	
graph export $git/results/check_`var'.png, replace	
}		

clear

** spot check how different after 1 month than after 16 months

use $dta/tmp/cps_imm_base.dta, clear

gen lt_coll = educ<100
gen male = sex==1
gen mexico = bpl==20000
gen age_at_imm = age - time_in_US

gen f_yr = floor(cpsid/10000000000)
gen f_mo = floor( (cpsid - f_yr*10000000000)/100000000 )

gen sample_month = ym(year, month) - ym(f_yr, f_mo) + 1

*keep if sample_month==1
keep if sample_month==16

collapse (mean) lt_coll male mexico age age_at_imm [aw=awtB], by(yrimmig_est time_in_US year)
	
keep if inlist(yrimmig_est, 2001, 2003, 2005, 2007, 2009, 2011, 2013, 2015, 2017, 2019, 2021, 2023)		

label var lt_coll 	"Share of Imm. Cohort with Less Than College Educ."
label var male 		"Male Share of Imm. Cohort"
label var mexico 	"Share of Imm. Cohort from Mexico"
label var age 		"Average Age of Imm. Cohort"
label var age_at_imm  "Average Age at Arrival of Imm. Cohort"

foreach var of varlist lt_coll male mexico age_at_imm {

local col1 gs10
local col2 red
local col3 purple
twoway  (scatter `var' year if time_in_US==0 & yrimmig_est<2020, mc(`col1'%60)) || ///
		(line `var' year if yrimmig_est==2001, lc(`col1'%64)) || ///
		(line `var' year if yrimmig_est==2003, lc(`col1'%68)) || ///
		(line `var' year if yrimmig_est==2005, lc(`col1'%72)) || ///
		(line `var' year if yrimmig_est==2007, lc(`col1'%76)) || ///
		(line `var' year if yrimmig_est==2009, lc(`col1'%80)) || ///
		(line `var' year if yrimmig_est==2011, lc(`col1'%84)) || ///
		(line `var' year if yrimmig_est==2013, lc(`col1'%88)) || ///
		(line `var' year if yrimmig_est==2015, lc(`col1'%92)) || ///
		(line `var' year if yrimmig_est==2017, lc(`col1'%96)) || ///
		(line `var' year if yrimmig_est==2019, lc(`col1'%100)) || ///
		(scatter `var' year if time_in_US==0 & yrimmig_est==2021, mc(`col2')) || ///
		(line `var' year if yrimmig_est==2021, lc(`col2')) || ///
		(scatter `var' year if time_in_US==0 & yrimmig_est==2023, mc(`col3')) || ///
		(line `var' year if yrimmig_est==2023, lc(`col3')), ///
		legend(off) ylab(, nogrid) xlab(, nogrid) xtitle("Year")
	
sleep 5000
}		

clear

** quality check
use $dta/tmp/cps_imm_base.dta, clear

keep yrimmig_est time_in_US year awtB qyrimmig
tab qyrimmig, gen(qualyr_)

line qualyr_1 year if time_in_US==0
line qualyr_6 year if time_in_US==0
line qualyr_9 year if time_in_US==0

	
