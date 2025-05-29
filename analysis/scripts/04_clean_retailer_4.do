// 04. Import raw data: Retailer D

clear all

// Create unique panel by website_id period_id

* Raw data
use "$BASE/Data/D/retailer4_allergy_all.dta" if date >= td(09apr2018) & date <= td(02oct2019), clear
gen tiebreaker = _n

* Drop if website_id is missing
count
local total = `r(N)'
count if website_id == "null" | website_id == "" & price != .
di `r(N)'/`total'
assert `r(N)'/`total' < 0.005
drop if website_id == "null" | website_id == ""

* Check for duplicate observations
bysort website_id period_id (tiebreaker): gen count = _N
tab count

* Duplicates in all variables except scrapeorder & scrape_version & time
duplicates drop website_id period_id date hour upc price stars n_reviews ///
	name item_code size retail_price not_available_online, force
	
* Drop no stars, no n_reviews, or no price (poor capture) if multiple observations
gen no_stars = stars == .
gen no_n_reviews = n_reviews == .
gen no_price = price == .
bysort website_id period_id (no_stars no_n_reviews no_price tiebreaker): drop if _n > 1 & (no_stars | no_n_reviews | no_price)
	
* For remaining duplicates, use later observations
drop count
bysort website_id period_id (tiebreaker): gen count = _N
tab count
summ count
assert `r(mean)' < 1.005
bysort website_id period_id (time tiebreaker): keep if _n == _N

isid website_id period_id
gen website = "D"

destring retail_price, replace

keep website website_id period_id date hour price stars n_reviews not_available_online retail_price
order website website_id period_id date hour price stars n_reviews not_available_online retail_price
compress

save "$DATA/retailer4_allergy_clean.dta", replace

