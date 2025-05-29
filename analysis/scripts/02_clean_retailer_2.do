// 02. Import raw data: Retailer E

clear all

// Create unique panel by website_id period_id

* Raw data
use "$BASE/Data/E/retailer2_allergy_all.dta" if date >= td(09apr2018) & date <= td(02oct2019), clear
gen tiebreaker = _n

* Drop if website_id is missing
count
local total = `r(N)'
count if website_id == "null" | website_id == "" & price != .
di `r(N)'/`total'
assert `r(N)'/`total' < 0.08		
drop if website_id == "null" | website_id == ""

* Check for duplicate observations
bysort website_id period_id (tiebreaker): gen count = _N
tab count

* Duplicates in all variables except scrapeorder & scrape_version & time
duplicates drop website_id period_id date hour price stars n_reviews ///
	product_linkhref name reg_price only_in_store item_code sku prodid ///
	item_size not_available_online item_size2 first_review unit_price item_code2, force

* Drop no stars, no n_reviews, or no price (poor capture) if multiple observations
gen no_stars = stars == .
gen no_n_reviews = n_reviews == .
gen no_price = price == .
bysort website_id period_id (no_stars no_n_reviews no_price tiebreaker): drop if _n > 1 & (no_stars | no_n_reviews | no_price)
	
* Drop mismatched quantities (poor capture)
gen quant1 = regexs(1) if regexm(item_size, "(^[0-9\\.]+)") 
gen quant2 = regexs(1) if regexm(item_size2, "(^[0-9\\.]+)") 
gen quant_match = quant1 == quant2 & quant1 != ""
egen has_quant_match = max(quant_match), by(website_id period_id)
drop if quant_match == 0 & has_quant_match & count > 1

drop count
bysort website_id period_id (tiebreaker): gen count = _N
tab count

* Miscoded item code do not match the modal quantity/size
gen quant = quant1 if quant_match
bysort item_code quant (tiebreaker): gen count_quant = _N
bysort item_code (quant_match count_quant tiebreaker): gen mode_quant = quant[_N]
egen total_count_quant = sum(quant != ""), by(item_code)
bysort item_code (quant_match count_quant tiebreaker): gen mode_quant_rate = count_quant[_N]/total_count_quant[_N]
summ mode_quant_rate, detail
drop if quant != mode_quant & quant != "" 	

* Using individual measures, rather than matched measures
gen quant_match1 = quant1 == mode_quant 
gen quant_match2 = quant2 == mode_quant
egen has_quant_match1 = max(quant_match1), by(website_id period_id)
egen has_quant_match2 = max(quant_match2), by(website_id period_id)
drop if quant_match1 == 0 & has_quant_match1 == 1 & has_quant_match2 == 0 
drop if quant_match2 == 0 & has_quant_match1 == 0 & has_quant_match2 == 1

* For remaining duplicates, use smaller quantity
drop count
bysort website_id period_id (tiebreaker): gen count = _N
tab count
summ count
assert `r(mean)' < 1.002
destring quant1, replace
destring quant2, replace
bysort website_id period_id (quant1 quant2 tiebreaker): keep if _n == 1

isid website_id period_id
gen website = "E"

keep website website_id period_id date hour price stars n_reviews not_available_online only_in_store reg_price unit_price first_review
order website website_id period_id date hour price stars n_reviews not_available_online only_in_store reg_price unit_price first_review
compress

save "$DATA/retailer2_allergy_clean.dta", replace
