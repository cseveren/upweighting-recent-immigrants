** ANALYZE FOREIGN-BORN POPULATION
import delim using "$dta/CES/file.csv", clear
destring period, replace i("M")
rename period month

drop seriesid label
gen yrmo = ym(year, month)
format yrmo %tm

rename value ces
replace ces = ces*1000

keep if year>=1994
save "./final/ces.dta", replace

**

** ANALYZE FOREIGN-BORN POPULATION
clear
import excel using "./CES/SeriesReport-20240424140122_f46f84.xlsx", firstrow cellrange(A13)
destring Period, replace i("M")
rename Period month

gen yrmo = ym(Year, month)
format yrmo %tm
drop if mi(yrmo)

rename Value ces_sa
drop Year month SeriesID

save "./final/ces_sa.dta", replace
