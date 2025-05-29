// 05. Import raw data: Retailer B

clear all

// Create unique panel by website_id period_id

* Raw data
use "$BASE/Data/B/retailer5_allergy_all.dta" if date >= td(09apr2018) & date <= td(02oct2019), clear
gen tiebreaker = _n

* Drop if website_id is missing
count
local total = `r(N)'
count if website_id == "null" | website_id == "" & price != .
di `r(N)'/`total'
assert `r(N)'/`total' < 0.0001
drop if website_id == "null" | website_id == ""

* Check for duplicate observations
bysort website_id period_id (tiebreaker): gen count = _N
tab count

* Duplicates in all variables except scrapeorder & time & prod_linkhref
duplicates drop website_id period_id date hour upc price stars n_reviews ///
	name brand not_available ///
	health_rank allergy_rank not_available_online out_of_stock, force

* Drop no stars, no n_reviews, or no price (poor capture) if multiple observations
gen no_stars = stars == .
gen no_n_reviews = n_reviews == .
gen no_price = price == .
bysort website_id period_id (no_stars no_n_reviews no_price tiebreaker): drop if _n > 1 & (no_stars | no_n_reviews | no_price)
	
* Then, drop if brand information not provided
gen no_brand = brand == ""
bysort website_id period_id (no_brand tiebreaker): drop if no_brand[1] == 0 & no_brand == 1
	
* Retailer B has multi-pack products on the same page
gen is_multipack = regexm(name, "\([0-9] pack\)") | regexm(name, "\([0-9] Pack\)")
egen has_singlepack = max(1 - is_multipack), by(website_id)
tab is_multipack has_singlepack  
drop if is_multipack & has_singlepack 

* Two one-off issues
drop if website_id == "169080111" & name != "Xyzal 24hr Allergy Relief Antihistamine Tablets, 35ct"
drop if website_id == "52785147" & name != "Vicks Sinex Severe Original Ultra Fine Mist Nasal Spray Decongestant for Fast Relief of Cold and Allergy Congestion, 0.5 fl oz"
replace not_available = "Item not available" if regexm(not_available, "$Item not available")

* For remaining duplicates, use later observations
drop count
bysort website_id period_id (tiebreaker): gen count = _N
tab count
summ count
assert `r(mean)' < 1.01
bysort website_id period_id (time tiebreaker): keep if _n == _N

isid website_id period_id
gen website = "B"

keep website website_id period_id date hour price stars n_reviews not_available_online out_of_stock not_available health_rank allergy_rank
order website website_id period_id date hour price stars n_reviews not_available_online out_of_stock not_available health_rank allergy_rank
compress

save "$DATA/retailer5_allergy_clean.dta", replace
