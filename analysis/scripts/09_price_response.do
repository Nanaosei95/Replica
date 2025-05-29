

// 1. Response to Retailer D

use "$DATA/analysis_data.dta", clear
assert price_change != .
drop if price == .
encode website, gen(website_code)

// drop if price == .

isid website_code product_id period_id
keep product_id website_code product_id period_id price price_change

gen hour_of_week = mod(period_id, 168)
tab hour_of_week if price_change == 1 & website_code == 4 // Between 5 and 9 on Sunday

* Shift hour of week to 0 = 5am 
local pre_period = 48
gen did_time = mod(period_id + `pre_period' - 5, 168) - `pre_period'
tab did_time if price_change == 1 & website_code == 4

gen did_week = floor((period_id + `pre_period' - 5)/168)
sort product_id period_id

egen max_price = max(price), by(website_code product_id did_week)
drop if max_price == .

egen has_change = max(price_change*(did_time >= 0 & did_time <= 5)*website_code == 4), by(product_id did_week)
tab has_change, mi
tab has_change if did_time == 0 & website_code == 4, mi
assert has_change != .
drop if has_change == .

isid website_code product_id did_week did_time

* Plots
preserve
	* Collapse to calculate average change by website and did_time
	collapse (mean) price_change, by(did_time has_change website_code)
	reshape wide price_change, i(website_code did_time) j(has_change)
	
	* Mean difference in rates in pre-period
	gen coef_pr = price_change1 - price_change0
	egen temp_pre_pr = mean(coef_pr) if did_time <= -1, by(website_code) // Use all in the pre-period because cumulative
	egen pre_pr = max(temp_pre_pr), by(website_code)
	
	* Construct cumulative probability, netting out mean differences in rates
	bysort website_code (did_time): gen baseline_pr = sum(price_change0)
	bysort website_code (did_time): gen treatment_pr = sum(price_change1 - pre_pr)
	
	export delimited using "$RESULTS/price_response_figure_data_D.csv" if inlist(did_time, -48, -1, 0, 23, 47, 71, 95, 119), replace

	forvalues i = 1/5 {
		twoway (line treatment_pr did_time if website_code == `i', lcolor(black)) ///
			(line baseline_pr did_time if website_code == `i', lcolor(black*.6) lpattern("--")), ///
			xline(0, lcolor(gray) lpattern(dash))  ///
			ylabel(, tposition(inside) angle(horizontal) labsize(large)) ///
			xlabel(-48(24)120, tposition(inside) labsize(large)) scheme(s1mono) ///
			ytitle("Cumulative Price Changes", size(large)) xtitle("Hours After Price Change Opportunity for D", size(large))  xlabel(-48(24)120) ///
			legend(region(lcolor(white))  order(1 "Price Change by D" 2 "No Price Change by D (Control)") cols(1) size(large))  
		graph export "$FIGURES/pr_price_response_D_`i'.pdf", replace
	}
restore

* Regressions
gen post = did_time >= 0
gen post_has_change = post*has_change
egen product_week = group(product_id did_week)

local cutoff = 72
preserve
	replace price_change = price_change*72 // Scale to 72 hours
	keep if did_time < `cutoff'
	reghdfe price_change post_has_change if website_code == 1, absorb(product_week did_time)
	summ price_change if e(sample)==1, meanonly
	estadd scalar ymean = r(mean), replace
	eststo a3d
	reghdfe price_change post_has_change if website_code == 2, absorb(product_week did_time)
	summ price_change if e(sample)==1, meanonly
	estadd scalar ymean = r(mean), replace
	eststo b3d
	reghdfe price_change post_has_change if website_code == 3, absorb(product_week did_time)
	summ price_change if e(sample)==1, meanonly
	estadd scalar ymean = r(mean), replace
	eststo c3d
	reghdfe price_change post_has_change if website_code == 4, absorb(product_week did_time)
	summ price_change if e(sample)==1, meanonly
	estadd scalar ymean = r(mean), replace
	eststo d3d
restore


// 2. Response to Retailer E

use "$DATA/analysis_data.dta", clear
drop if price == .
assert price_change != .
encode website, gen(website_code)

isid website_code product_id period_id
keep product_id website_code product_id period_id price price_change

gen hour_of_week = mod(period_id, 168)
tab hour_of_week if price_change == 1 & website_code == 5 // Between 5 and 9 on Sunday

* Shift hour of week to 0 = 5am 
local pre_period = 48
gen did_time = mod(period_id + `pre_period' - 5, 168) - `pre_period'
tab did_time if price_change == 1 & website_code == 5

gen did_week = floor((period_id + `pre_period' - 5)/168)
sort product_id period_id

egen max_price = max(price), by(website_code product_id did_week)
drop if max_price == .

egen has_change = max(price_change*(did_time >= 0 & did_time <= 5)*website_code == 5), by(product_id did_week)
tab has_change, mi
tab has_change if did_time == 0 & website_code == 5, mi
assert has_change != .
drop if has_change == .

isid website_code product_id did_week did_time

* Plots
preserve
	* Collapse to calculate average change by website and did_time
	collapse (mean) price_change, by(did_time has_change website_code)
	reshape wide price_change, i(website_code did_time) j(has_change)
	
	* Mean difference in rates in pre-period
	gen coef_pr = price_change1 - price_change0
	egen temp_pre_pr = mean(coef_pr) if did_time <= -1, by(website_code) // Use all in the pre-period because cumulative
	egen pre_pr = max(temp_pre_pr), by(website_code)
	
	* Construct cumulative probability, netting out mean differences in rates
	bysort website_code (did_time): gen baseline_pr = sum(price_change0)
	bysort website_code (did_time): gen treatment_pr = sum(price_change1 - pre_pr)
	
	export delimited using "$RESULTS/price_response_figure_data_E.csv" if inlist(did_time, -48, -1, 0, 23, 47, 71, 95, 119), replace

	forvalues i = 1/5 {
		twoway (line treatment_pr did_time if website_code == `i', lcolor(black)) ///
			(line baseline_pr did_time if website_code == `i', lcolor(black*.6) lpattern("--")), ///
			xline(0, lcolor(gray) lpattern(dash))  ///
			ylabel(, tposition(inside) angle(horizontal) labsize(large)) ///
			xlabel(-48(24)120, tposition(inside) labsize(large)) scheme(s1mono) ///
			ytitle("Cumulative Price Changes", size(large)) xtitle("Hours After Price Change Opportunity for E", size(large))  xlabel(-48(24)120) ///
			legend(region(lcolor(white))  order(1 "Price Change by E" 2 "No Price Change by E (Control)") cols(1) size(large))  
		graph export "$FIGURES/pr_price_response_E_`i'.pdf", replace
	}
restore



* Regressions
gen post = did_time >= 0
gen post_has_change = post*has_change

egen product_week = group(product_id did_week)

local cutoff = 72
preserve
	replace price_change = price_change*72 // Scale to 72 hours
	keep if did_time < `cutoff'
	reghdfe price_change post_has_change if website_code == 1, absorb(product_week did_time)
	summ price_change if e(sample)==1, meanonly
	estadd scalar ymean = r(mean), replace
	eststo a3
	reghdfe price_change post_has_change if website_code == 2, absorb(product_week did_time)
	summ price_change if e(sample)==1, meanonly
	estadd scalar ymean = r(mean), replace
	eststo b3
	reghdfe price_change post_has_change if website_code == 3, absorb(product_week did_time)
	summ price_change if e(sample)==1, meanonly
	estadd scalar ymean = r(mean), replace
	eststo c3
	reghdfe price_change post_has_change if website_code == 4, absorb(product_week did_time)
	summ price_change if e(sample)==1, meanonly
	estadd scalar ymean = r(mean), replace
	eststo d3
restore


// 3. Output regression table

* Display results
estout a3d b3d c3d a3 b3 c3, cells(b(fmt(3) star) se(fmt(3) par)) stats(ymean ar2 N, fmt(1 3 %12.0fc) labels("Outcome Mean" "Adjusted R2" "Observations")) starlevels(* 0.1 ** 0.05 *** 0.01)

* Output for latex with results for retailers A & B
label var post_has_change "Post\textsubscript{h(t)}$\times$ PriceChange\textsubscript{w(t)}"

esttab a3d b3d a3 b3 using "$TABLES/price_response_72_a.tex", frag cells(b(fmt(3) star) se(fmt(3) par)) ///
	stats() keep(post_has_change) ///
	starlevels(`"\sym{*}"' 0.1 `"\sym{**}"' 0.05 `"\sym{***}"' 0.01, label(" \(p<@\)")) ///
	varwidth(20) modelwidth(12) delimiter(&) end(\\) ///
	noobs collabels(none) booktabs gaps nonumber label  nonote replace nomtitles nodepvars 

esttab a3d b3d a3 b3 using "$TABLES/price_response_72_b.tex", frag	cells(b(fmt(3) star)) ///
	drop(*)  stats(ymean N, fmt(3 %12.0fc) labels("Outcome Mean" "Observations") ///
	layout("\multicolumn{1}{c}{@}" "\multicolumn{1}{c}{@}")) ///
	varwidth(20) modelwidth(12) delimiter(&) end(\\) collabels(none) nolines ///
	nonumber label  nonote replace nomtitles nodepvars noisily 
		

