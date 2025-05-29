clear all

****************************************************************
* Import product list
****************************************************************

clear
import excel using "$DATA/product_list/product_list_20191004.xlsx", firstrow
format mode_name %80s

* Keep common forms
tab form, mi
keep if inlist(form, "Chewable Tablet", "Dissolvable Tablet", "Gelcap", "Liquid", "Spray", "Tablet") // Common forms

* Generate variant variable
replace decongestant = 0 if decongestant == .
egen variant = group(decongestant childrens is12hour)
tab variant, mi

tab brand, mi

*Drop if missing key information
drop if brand == "" | drug == "" | form == "" | variant == .  | size == .

* Only keep multipack of 2 (or 1)
replace multipack = 1 if multipack == .
assert multipack != . & multipack >= 1
tab multipack website, mi
drop if multipack > 2

keep website website_id drug brand form variant multipack size count childrens is24hour is12hour decongestant ///
	mode_name mode_size mode_size2 mode_sku mode_prodid mode_upc mode_brand problem_PT changed_PT changed_PT2
order website website_id drug brand form variant multipack size count childrens is24hour is12hour decongestant ///
	mode_name mode_size mode_size2 mode_sku mode_prodid mode_upc mode_brand problem_PT changed_PT changed_PT2
	
saveold "$DATA/product_list/product_list_select1.dta", replace

****************************************************************
* Merge observations with product attributes
****************************************************************

* Load data
clear
use "$DATA/retailer1_allergy_clean.dta"
append using "$DATA/retailer2_allergy_clean.dta"
append using "$DATA/retailer3_allergy_clean.dta"
append using "$DATA/retailer4_allergy_clean.dta"
append using "$DATA/retailer5_allergy_clean.dta"
compress

* Select priority products
merge m:1 website website_id using "$DATA/product_list/product_list_select1.dta", keepusing(drug brand form size variant count multipack childrens is24hour is12hour decongestant)
assert _merge != 2
keep if _merge == 3
drop _merge

* Set price to missing if not available online
replace price = . if not_available_online == 1
replace price = . if not_available == "Item not available"
replace price = . if only_in_store == "Out of stock online"

save "$DATA/temp_06.dta", replace

* Multiple listings for the same product
bysort website drug brand form size multipack variant period_id: gen count_products = _N
bysort website drug brand form size multipack variant period_id: gen first = _n == 1
tab count_products website if first
drop count_products first

****************************************************************
* Select website_id with most valid observations, for otherwise identical products
****************************************************************

use "$DATA/temp_06.dta", clear

* Select website_id with the most price observations, weighted by n_reviews
gen price_obs = price != .
* Using 95th percentile of reviews to eliminate tail error
summ n_reviews, detail
sort website website_id
egen mode_price = mode(price), by(website website_id)
collapse (p95) n_reviews (sum) price_obs (first) drug brand form variant multipack size mode_price count childrens is24hour is12hour decongestant, by(website website_id)
tab website brand

* Only keep multipack == 1 | multipack == 2
assert inlist(multipack, 1, 2)

* Select website_id with most (weighted) reviews if there are multiple of the same product
gen tiebreak = _n // tiebreak in case of ties
replace n_reviews = 0 if n_reviews == .
assert price_obs != . & n_reviews != .
gen weighted_reviews = n_reviews*price_obs
bysort website drug brand form variant multipack size (weighted_reviews tiebreak): gen count_products = _N
bysort website drug brand form variant multipack size (weighted_reviews tiebreak): gen last = _n == _N
preserve
	keep if count_products > 1
	save "$DATA/product_list/check1_duplicate_products.dta", replace
restore
tab count_products website if last
keep if last
tab website brand

rename n_reviews n_reviews_p_95

egen max_n_reviews = max(n_reviews_p_95), by(website)
gen scaled_n_reviews = n_reviews_p_95/max_n_reviews*100
format scaled_n_reviews %9.1f

* Calculate size down and up and relevant prices
bysort website drug brand form variant multipack (size): gen size_down = size[_n-1]
bysort website drug brand form variant multipack (size): gen mode_price_size_down = mode_price[_n-1]
bysort website drug brand form variant multipack (size): gen size_up = size[_n+1]
bysort website drug brand form variant multipack (size): gen mode_price_size_up = mode_price[_n+1]
assert size != size_down & size != size_up
preserve
	keep if (mode_price > mode_price_size_up  & mode_price != . & mode_price_size_up != .) | (mode_price < mode_price_size_down & mode_price != . & mode_price_size_down != .)
	save "$DATA/product_list/check2_mode_price_mismatch.dta", replace
restore
keep website website_id price_obs n_reviews_p_95 scaled_n_reviews size_down mode_price_size_down size_up mode_price_size_up
save "$DATA/product_list/product_list_select2.dta", replace

****************************************************************
* Select unique products and create full panel
****************************************************************

use "$DATA/temp_06.dta", clear
merge m:1 website website_id using "$DATA/product_list/product_list_select2.dta"
assert _merge != 2
keep if _merge == 3
drop _merge

order website website_id period_id date hour price stars n_reviews drug brand form variant multipack size  

* Create product id
egen product_id = group(drug brand form variant multipack size)
isid product_id website date hour
compress

* Create full panel
isid product_id website period_id
egen product_website_id = group(product_id website)
tsset product_website_id period_id
gen flag_missing_price = price == .
tab flag_missing_price
tsfill

* Fill in characteristics
bysort product_website_id (period_id): carryforward website, replace
bysort product_website_id (period_id): carryforward website_id, replace
bysort product_website_id (period_id): carryforward product_id, replace
bysort product_website_id (period_id): carryforward drug, replace
bysort product_website_id (period_id): carryforward brand, replace
bysort product_website_id (period_id): carryforward form, replace
bysort product_website_id (period_id): carryforward variant, replace
bysort product_website_id (period_id): carryforward multipack, replace
bysort product_website_id (period_id): carryforward size, replace

* Check dates, and fill in
gen date_check = floor((period_id-1)/24) + td(08apr2018)
format date_check %td
assert date_check == date if date != .
gen hour_check = mod((period_id-1),24)
assert hour_check == hour if hour != .
replace date = date_check if date == .
replace hour = hour_check if hour == .
bysort period_id: assert date == date[1]
bysort period_id: assert hour == hour[1]
drop date_check hour_check


* Replace poor capture by retailer E 
egen daily_mode_price = mode(price) if website == "E", by(website website_id date)
bysort website period_id brand drug form variant (size): gen daily_mode_price_size_down = daily_mode_price[_n-1]
bysort website period_id brand drug form variant (size): gen daily_mode_price_size_up = daily_mode_price[_n+1]
gen price_diff_size_down = price - daily_mode_price_size_down
replace price_diff_size_down = round(price_diff_size_down, 0.01)
gen price_diff_size_up = price - daily_mode_price_size_up
replace price_diff_size_up = round(price_diff_size_up, 0.01)
replace price = . if price_diff_size_down <= 0 & price_diff_size_down != . & website == "E"
replace price = . if price_diff_size_up >= 0 & price_diff_size_up != . & website == "E"

* Impute prices, but only for short spells
sort product_website_id period_id
tsspell price
egen spell_length = max(_seq), by(product_website_id _spell)
replace flag_missing_price = 1 if flag_missing_price == .
bysort product_website_id (period_id): carryforward price if spell_length <= 6, replace
gen flag_imputed_price = price != . & flag_missing_price == 1
gen is_observed = price != . & flag_imputed_price == 0

* Fixing measurement issue with price changes: eliminate switchbacks
* Three passes to elimate AAABABAAA pattern
forvalues iter = 1/3 {
	bysort product_website_id (period_id): assert period_id == period_id[_n-1] + 1 if _n > 1 // Check for no gaps
	bysort product_website_id (period_id): gen is_price_change = price != price[_n-1]
	bysort product_website_id (period_id): replace is_price_change = 0 if price == . | price[_n-1] == .
	bysort product_website_id (period_id): gen is_switchback = price == price[_n-2] & is_price_change
	tab is_price_change is_switchback
	tab website is_switchback if is_price_change

	* Fixing switchback issue for non-hourly pricing tech websites
	replace is_switchback = 0 if inlist(website, "A", "B") // These have hourly pricing tech.
	bysort product_website_id (period_id): replace price = price[_n+1] if is_switchback[_n+1] == 1
	drop is_price_change is_switchback
}

bysort product_website_id (period_id): gen price_change = price != price[_n-1]
bysort product_website_id (period_id): replace price_change = 0 if price == . | price[_n-1] == .
tab website price_change 

* Drop end periods
summ date
drop if date == `r(min)' | date == `r(max)'

rename website_id website_id0
egen website_id = group(website_id0)
drop website_id0
order website website_id period_id

* Drop extra variables
drop stars n_reviews not_available_online only_in_store reg_price unit_price first_review ///
	see_low_price_in_cart left_in_stock out_of_stock retail_price not_available health_rank ///
	allergy_rank n_reviews_p_95 price_obs scaled_n_reviews ///
	size_down mode_price_size_down size_up mode_price_size_up daily_mode_price ///
	daily_mode_price_size_down daily_mode_price_size_up price_diff_size_down price_diff_size_up ///
	_spell _seq _end spell_length

compress
save "$DATA/analysis_data.dta", replace
