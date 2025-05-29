clear all

use "$DATA/analysis_data.dta", clear
* Checking product definitions

egen mode_price = mode(price), by(website website_id)
collapse (mean) price (max) max_price = price (min) min_price = price (first) mode_price ///
	drug brand form variant multipack size childrens is24hour is12hour decongestant, by(website website_id)
bysort drug brand form variant multipack size: gen count_sites = _N

drop count_sites
egen product_id = group(drug brand form variant multipack size)
egen product_unit = group(drug brand form variant multipack)
isid product_id website
bysort product_id: gen count_sites = _N
tab count_sites 

egen website_code = group(website)
gen inv_size = 1/size
gen unit_price = price/size

gen ln_unit_price = ln(unit_price)

tab website, gen(i_)
gen i_A_inv_size = i_1*inv_size
gen i_B_inv_size = i_2*inv_size
gen i_C_inv_size = i_3*inv_size
gen i_D_inv_size = i_4*inv_size
gen i_E_inv_size = i_5*inv_size

summ price if count_sites > 2
summ price if count_sites > 4

* All products sold on at least three websites
keep if count_sites > 2

areg unit_price inv_size i_2 i_3 i_4 i_5, absorb(product_unit)
estimates store a1

areg unit_price i_A_inv_size i_B_inv_size i_C_inv_size i_D_inv_size i_E_inv_size i_2 i_3 i_4 i_5, absorb(product_unit)
estimates store a2

areg unit_price i_A_inv_size i_B_inv_size i_C_inv_size i_D_inv_size i_E_inv_size i_2 i_3 i_4 i_5 size, absorb(product_unit)
estimates store a3

* All products sold on all five websites
keep if count_sites > 4

areg unit_price inv_size i_2 i_3 i_4 i_5, absorb(product_unit)
estimates store a4

areg unit_price i_A_inv_size i_B_inv_size i_C_inv_size i_D_inv_size i_E_inv_size i_2 i_3 i_4 i_5, absorb(product_unit)
estimates store a5

areg unit_price i_A_inv_size i_B_inv_size i_C_inv_size i_D_inv_size i_E_inv_size i_2 i_3 i_4 i_5 size, absorb(product_unit)
estimates store a6

estadd local unit_fe "X" : a1 a2 a3 a4 a5 a6
estadd local all_5 "X" : a4 a5 a6

label variable i_2 "Unit Price Premium (B)"
label variable i_3 "Unit Price Premium (C)"
label variable i_4 "Unit Price Premium (D)"
label variable i_5 "Unit Price Premium (E)"

label variable inv_size "Fixed Component (All)"
label variable i_A_inv_size "Fixed Component (A)"
label variable i_B_inv_size "Fixed Component (B)"
label variable i_C_inv_size "Fixed Component (C)"
label variable i_D_inv_size "Fixed Component (D)"
label variable i_E_inv_size "Fixed Component (E)"
label variable size "Quantity Discount"

esttab a1 a3 a4 a6 using "$TABLES/tab_shipping_costs.tex", replace booktabs frag ///
	label se(%9.3f) b(%9.3f) noobs ///  
	drop(_cons) ///
	order(inv_size i_A_inv_size i_B_inv_size i_C_inv_size i_D_inv_size i_E_inv_size i_2 i_3 i_4 i_5 size) ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	alignment(S[table-format = 2.5]) ///
	stats(unit_fe all_5 N r2, fmt(%12s %12s %10.0fc %9.3f) ///
	layout("\multicolumn{1}{c}{@}" "\multicolumn{1}{c}{@}" "\multicolumn{1}{c}{@}") ///
	labels(`"Product FEs"' `"Sold at All Retailers"' `"Observations"' `"\(R^{2}\)"')) ///
	nomtitles 
	
	
reg price i.website_code, absorb(product_unit)