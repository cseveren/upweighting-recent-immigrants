clear

set obs 31
gen time_in_US = _n-1

tempfile timeus
save "`timeus'"

import excel using "$dta/inputs/CPS_NonResponse/$nonresp", clear firstrow cellrange(A12)

drop if mi(Year)

rename Jan m_1
rename Feb m_2
rename Mar m_3
rename Apr m_4
rename May m_5
rename Jun m_6
rename Jul m_7
rename Aug m_8
rename Sep m_9
rename Oct m_10
rename Nov m_11
rename Dec m_12

reshape long m_, i(Year) j(Month)
rename m_ nonresp
rename Year year
rename Month month

cross using "`timeus'"
sort year month time_in_US

gen nonresp_adj_base = 0.5*(100-nonresp)/100
gen nonresp_adj = 1 - nonresp_adj_base * max((1 - time_in_US/10),0)

drop nonresp_adj_base nonresp
drop if mi(nonresp_adj)

compress
save "$git/adjustments/nonresp_adj.dta", replace
export delim using "$git/adjustments/nonresp_adj.csv", replace

