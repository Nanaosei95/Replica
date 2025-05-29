clear all

use "$DATA/analysis_data.dta", clear
encode website, gen(website_code)

assert product_id != .
gen ln_price = ln(price)
isid product_id period_id website
bysort product_id period_id (website): gen temp_count_sites = _N
egen product_count_sites = max(temp_count_sites), by(product_id)


reghdfe ln_price i.website_code, absorb(product_id period_id)
estimates store a1
predict ln_premium, xb
replace ln_premium = ln_premium - _b[_cons]

	* Also holds for the maximum price on a website on a given day
	bysort website website_id date: gen first = _n == 1
	egen max_price = max(price), by(website product_id date)
	gen ln_max_price = ln(max_price)
	reghdfe ln_max_price i.website_code if first, absorb(product_id date)

reghdfe ln_price i.website_code if product_count_sites == 5, absorb(product_id period_id)
predict ln_premium2, xb
replace ln_premium2 = ln_premium2 - _b[_cons]
estimates store a2

reghdfe ln_price i.website_code if date >= td(01jul2019), absorb(product_id period_id)
predict ln_premium3, xb
replace ln_premium3 = ln_premium3 - _b[_cons]
estimates store a3
	
reghdfe ln_price i.website_code if product_count_sites == 5 &  date >= td(01jul2019), absorb(product_id period_id)
predict ln_premium4, xb
replace ln_premium4 = ln_premium4 - _b[_cons]
estimates store a4

estadd local product_fe "Yes" : a1
estadd local product_fe "Yes" : a2
estadd local product_fe "Yes" : a3
estadd local product_fe "Yes" : a4

estadd local period_fe "Yes" : a1
estadd local period_fe "Yes" : a2
estadd local period_fe "Yes" : a3
estadd local period_fe "Yes" : a4

estadd local restricted "Yes" : a2
estadd local restricted "Yes" : a4

estadd local first_half "Yes" : a3
estadd local first_half "Yes" : a4


esttab a1 a3 a2 a4 using "$TABLES/price_diff.tex", replace booktabs nonotes ///
	label se(%9.3f) b(%9.3f) ///  
	drop(1.website_code _cons) ///
	coeflabels(2.website_code "Retailer B" ///
		3.website_code "Retailer C" ///
		4.website_code "Retailer D" ///
		5.website_code "Retailer E") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	alignment(S[table-format = 4.4]) ///
	stats(product_fe period_fe restricted first_half N, fmt(%12s %12s %12s %12s %9.0fc) ///
		layout("\multicolumn{1}{c}{@}" "\multicolumn{1}{c}{@}" "\multicolumn{1}{c}{@}" "\multicolumn{1}{c}{@}" "\multicolumn{1}{c}{@}" ) ///
		labels(`"Product FEs"' `"Period FEs"' `"Sold at All Retailers"' `"On or After Jul 1 2019"' `"Observations"' )) ///
		nomtitles 

* Create plot

preserve
	bysort website: keep if _n == 1
	keep website ln_premium*

	save "$DATA/temp_premium.dta", replace
restore

* Calculating Pricing frequency
assert price_change != .
keep if price_change == 1
tab website

collapse (mean) mean_period = period_id (max) max_period = period_id (min) min_period = period_id ///
	(sum) count_price_change = price_change, by(website date)

bysort website (date): gen hour_gap = min_period - max_period[_n-1]

table website [fweight=count_price_change], c(mean hour_gap median hour_gap)

summ hour_gap if website == "A" [fweight=count_price_change], detail
summ hour_gap if website == "B" [fweight=count_price_change], detail
summ hour_gap if website == "C" [fweight=count_price_change], detail
summ hour_gap if website == "D" [fweight=count_price_change], detail
summ hour_gap if website == "E" [fweight=count_price_change], detail

collapse (median) hour_gap [fweight=count_price_change], by(website)

merge 1:1 website using "$DATA/temp_premium.dta"
assert _merge == 3
drop _merge
scatter ln_premium hour_gap
gen price_index = exp(ln_premium)*100
save "$DATA/temp_premium2.dta", replace


use "$DATA/temp_premium2.dta", clear
scatter price_index hour_gap, ///
	ylabel(100(10)140, tposition(inside) angle(horizontal) format(%4.0f))  ///
	xlabel(1 2 24 168, tposition(inside)) /// 
	xsc(reverse) xscale(log)  xscale(r(0.5 200)) yscale(r(95 130)) mlabel(website) mlabposition(12) mlabcolor(black*0.8) mcolor(black) mlabsize(medlarge) msize(2.5) ///
	ytitle("Price Index") xtitle("Pricing Frequency: Median Hours Between Updates (Log Scale)") plotregion(margin(l+3))
graph export "$FIGURES/plot_technology_premium.pdf", replace


* Export prices and shares for simulation
import delimited using "$DATA/google_search_shares.csv", clear
rename average share
merge 1:1 website using "$DATA/temp_premium2.dta"
assert _merge == 3
drop _merge
keep website share price_index
order website price_index share
export delimited using "$SIM/prices_shares.csv", replace
		
		
* Identify price changes by hour of week
use "$DATA/analysis_data.dta", clear
gen hour_eastern = mod(hour + 24 - 4, 24) // Convert to EDT
gen dow = dow(date)

replace dow = -1 if dow==6 // Start Saturday morning at midnight
gen hourofweek = 24 + dow*24 + hour_eastern

collapse (sum) is_observed price_change, by(website hourofweek) fast

egen total_price_change = sum(price_change), by(website)
gen hourly_dist = price_change/total_price_change * 100
gen hourly_freq = price_change/is_observed

twoway (line hourly_dist hourofweek if website == "A", lcolor(black)), ///
		ytitle("Percent of Price Changes", size(huge)) xtitle("Hour of Week", size(huge)) ///
		ylabel(0(0.2)1, tposition(inside) angle(horizontal) format(%4.1f) labsize(large)) ///
		xlabel(0(24)168, tposition(inside) labsize(large)) scheme(s1mono) ///
		xline(24, lp(dash) lc(black%40)) xline(48, lp(dash) lc(black%40)) xline(72, lp(dash) lc(black%40)) xline(96, lp(dash) lc(black%40)) xline(120, lp(dash) lc(black%40)) xline(144, lp(dash) lc(black%40)) ///
		text(0 12 "Sat", place(s) size(vlarge)) text(0 36 "Sun", place(s) size(vlarge)) text(0 60 "Mon", place(s) size(vlarge)) text(0 84 "Tue", place(s) size(vlarge)) text(0 108 "Wed", place(s) size(vlarge)) text(0 132 "Thu", place(s) size(vlarge)) text(0 156 "Fri", place(s) size(vlarge)) ///
		ysize(2) graphregion(margin(t=0)) plotregion(margin(l+1 b+4))
graph export "$FIGURES/price_change_fraction_hourofweek_A.pdf", replace

twoway (line hourly_dist hourofweek if website == "B", lcolor(black)), ///
		ytitle("Percent of Price Changes", size(huge)) xtitle("Hour of Week", size(huge)) ///
		ylabel(0(0.2)1, tposition(inside) angle(horizontal) format(%4.1f) labsize(large)) ///
		xlabel(0(24)168, tposition(inside) labsize(large)) scheme(s1mono) ///
		xline(24, lp(dash) lc(black%40)) xline(48, lp(dash) lc(black%40)) xline(72, lp(dash) lc(black%40)) xline(96, lp(dash) lc(black%40)) xline(120, lp(dash) lc(black%40)) xline(144, lp(dash) lc(black%40)) ///
		text(0 12 "Sat", place(s) size(vlarge)) text(0 36 "Sun", place(s) size(vlarge)) text(0 60 "Mon", place(s) size(vlarge)) text(0 84 "Tue", place(s) size(vlarge)) text(0 108 "Wed", place(s) size(vlarge)) text(0 132 "Thu", place(s) size(vlarge)) text(0 156 "Fri", place(s) size(vlarge)) ///
		ysize(2) graphregion(margin(t=0)) plotregion(margin(l+1 b+4))
graph export "$FIGURES/price_change_fraction_hourofweek_B.pdf", replace

twoway (line hourly_dist hourofweek if website == "C", lcolor(black)), ///
		ytitle("Percent of Price Changes", size(huge)) xtitle("Hour of Week", size(huge)) ///
		ylabel(0(2)8, tposition(inside) angle(horizontal) format(%4.0f) labsize(large)) ///
		xlabel(0(24)168, tposition(inside) labsize(large)) scheme(s1mono) ///
		xline(24, lp(dash) lc(black%40)) xline(48, lp(dash) lc(black%40)) xline(72, lp(dash) lc(black%40)) xline(96, lp(dash) lc(black%40)) xline(120, lp(dash) lc(black%40)) xline(144, lp(dash) lc(black%40)) ///
		text(0 12 "Sat", place(s) size(vlarge)) text(0 36 "Sun", place(s) size(vlarge)) text(0 60 "Mon", place(s) size(vlarge)) text(0 84 "Tue", place(s) size(vlarge)) text(0 108 "Wed", place(s) size(vlarge)) text(0 132 "Thu", place(s) size(vlarge)) text(0 156 "Fri", place(s) size(vlarge)) ///
		ysize(2) graphregion(margin(t=0)) plotregion(margin(l+1 b+4))
graph export "$FIGURES/price_change_fraction_hourofweek_C.pdf", replace

twoway (line hourly_dist hourofweek if website == "D", lcolor(black)), ///
		ytitle("Percent of Price Changes", size(huge)) xtitle("Hour of Week", size(huge)) ///
		ylabel(0(5)25, tposition(inside) angle(horizontal) format(%4.0f) labsize(large)) ///
		xlabel(0(24)168, tposition(inside) labsize(large)) scheme(s1mono) ///
		xline(24, lp(dash) lc(black%40)) xline(48, lp(dash) lc(black%40)) xline(72, lp(dash) lc(black%40)) xline(96, lp(dash) lc(black%40)) xline(120, lp(dash) lc(black%40)) xline(144, lp(dash) lc(black%40)) ///
		text(0 12 "Sat", place(s) size(vlarge)) text(0 36 "Sun", place(s) size(vlarge)) text(0 60 "Mon", place(s) size(vlarge)) text(0 84 "Tue", place(s) size(vlarge)) text(0 108 "Wed", place(s) size(vlarge)) text(0 132 "Thu", place(s) size(vlarge)) text(0 156 "Fri", place(s) size(vlarge)) ///
		ysize(2) graphregion(margin(t=0)) plotregion(margin(l+1 b+4))
graph export "$FIGURES/price_change_fraction_hourofweek_D.pdf", replace


twoway (line hourly_dist hourofweek if website == "E", lcolor(black)), ///
		ytitle("Percent of Price Changes", size(huge)) xtitle("Hour of Week", size(huge)) ///
		ylabel(0(10)60, tposition(inside) angle(horizontal) format(%4.0f) labsize(large)) ///
		xlabel(0(24)168, tposition(inside) labsize(large)) scheme(s1mono) ///
		xline(24, lp(dash) lc(black%40)) xline(48, lp(dash) lc(black%40)) xline(72, lp(dash) lc(black%40)) xline(96, lp(dash) lc(black%40)) xline(120, lp(dash) lc(black%40)) xline(144, lp(dash) lc(black%40)) ///
		text(0 12 "Sat", place(s) size(vlarge)) text(0 36 "Sun", place(s) size(vlarge)) text(0 60 "Mon", place(s) size(vlarge)) text(0 84 "Tue", place(s) size(vlarge)) text(0 108 "Wed", place(s) size(vlarge)) text(0 132 "Thu", place(s) size(vlarge)) text(0 156 "Fri", place(s) size(vlarge)) ///
		ysize(2) graphregion(margin(t=0)) plotregion(margin(l+1 b+4))
graph export "$FIGURES/price_change_fraction_hourofweek_E.pdf", replace

/*
* Slides: Make combined charts for A/B and E/D
twoway (line hourly_dist hourofweek if website == "A", lcolor(black%80)) (line hourly_dist hourofweek if website == "B", lcolor(sienna%80)),  ///
		ytitle("Percent of Price Changes", size(huge)) xtitle("Hour of Week", size(huge)) ///
		ylabel(0(0.2)1, tposition(inside) angle(horizontal) format(%4.1f) labsize(large)) ///
		xlabel(0(24)168, tposition(inside) labsize(large)) scheme(s1mono) ///
		xline(24, lp(dash) lc(black%40)) xline(48, lp(dash) lc(black%40)) xline(72, lp(dash) lc(black%40)) xline(96, lp(dash) lc(black%40)) xline(120, lp(dash) lc(black%40)) xline(144, lp(dash) lc(black%40)) ///
		text(0 12 "Sat", place(s) size(vlarge)) text(0 36 "Sun", place(s) size(vlarge)) text(0 60 "Mon", place(s) size(vlarge)) text(0 84 "Tue", place(s) size(vlarge)) text(0 108 "Wed", place(s) size(vlarge)) text(0 132 "Thu", place(s) size(vlarge)) text(0 156 "Fri", place(s) size(vlarge)) ///
		ysize(2) graphregion(margin(t=0)) plotregion(margin(l+1 b+4)) legend(off)
graph export "$FIGURES/price_change_fraction_hourofweek_AB.pdf", replace


twoway (line hourly_dist hourofweek if website == "D", lcolor(black%80)) (line hourly_dist hourofweek if website == "E", lcolor(sienna%80)),  ///
		ytitle("Percent of Price Changes", size(huge)) xtitle("Hour of Week", size(huge)) ///
		ylabel(0(10)50, tposition(inside) angle(horizontal) format(%4.0f) labsize(large)) ///
		xlabel(0(24)168, tposition(inside) labsize(large)) scheme(s1mono) ///
		xline(24, lp(dash) lc(black%40)) xline(48, lp(dash) lc(black%40)) xline(72, lp(dash) lc(black%40)) xline(96, lp(dash) lc(black%40)) xline(120, lp(dash) lc(black%40)) xline(144, lp(dash) lc(black%40)) ///
		text(0 12 "Sat", place(s) size(vlarge)) text(0 36 "Sun", place(s) size(vlarge)) text(0 60 "Mon", place(s) size(vlarge)) text(0 84 "Tue", place(s) size(vlarge)) text(0 108 "Wed", place(s) size(vlarge)) text(0 132 "Thu", place(s) size(vlarge)) text(0 156 "Fri", place(s) size(vlarge)) ///
		ysize(2) graphregion(margin(t=0)) plotregion(margin(l+1 b+4)) legend(off)
graph export "$FIGURES/price_change_fraction_hourofweek_DE.pdf", replace
*/
