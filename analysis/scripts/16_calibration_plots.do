clear all

import delimited "$SIM/sim_output.csv", delim(",") varn(1)

gen pricing_tech = firm - 1
replace pricing_tech = 0.9 if pricing_tech==0
replace pricing_tech = 1.1 if pricing_tech==1

// Bertrand nash price index
gen baseprice_tmp = estprice if firm==5
egen baseprice = mean(baseprice_tmp)
drop baseprice_tmp
gen estprice_sbn_index = estpstar_sbn / baseprice

label var priceindex "Actual"
label var estpriceindex "Pricing Algorithm Model (Calibrated)"
label var estprice_sbn_index "Simultaneous Bertrand-Nash Pricing (Counterfactual)"

label var share "Actual"
label var estshare "Pricing Algorithm Model (Calibrated)"
label var estshare_sbn "Simultaneous Bertrand-Nash Pricing (Counterfactual)"

gen website = "A" if firm == 5
replace website = "B" if firm == 4
replace website = "C" if firm == 3
replace website = "D" if firm == 2
replace website = "E" if firm == 1
assert website != ""

summ estprice
gen markup_data = priceindex*`r(min)'
gen markup_alg = estprice
gen markup_sbn = estpstar

label var markup_data "Actual"
label var markup_alg "Pricing Algorithm Model (Calibrated)"
label var markup_sbn "Simultaneous Bertrand-Nash Pricing (Counterfactual)"

twoway (scatter markup_data pricing_tech, mcolor(black%60) msize(2) msymbol(Sh)) ///
	(scatter markup_alg pricing_tech, mcolor(maroon%60) msize(2) msymbol(c))  ///
	(scatter markup_sbn pricing_tech, mcolor(navy%80) msize(2) msymbol(t)), ///
	ylabel(, tposition(inside) angle(horizontal) format(%4.1f)) xscale(r(.5 3.5)) ///
	xlabel(, tposition(inside)) /// 
	ytitle("Markup", size(large)) xtitle("Pricing Frequency", size(large)) legend(region(lcolor(white)) size(large) cols(1))
graph export "$FIGURES/plot_sim_prices_by_tech.pdf", replace

twoway (scatter share pricing_tech, mcolor(black%60) msize(2) msymbol(Sh)) ///
	(scatter estshare pricing_tech, mcolor(maroon%60) msize(2) msymbol(c))  ///
	(scatter estshare_sbn pricing_tech, mcolor(navy%80) msize(2) msymbol(t)), ///
	ylabel(0.1(0.05)0.35, tposition(inside) angle(horizontal) format(%4.2f)) xscale(r(.5 3.5)) ///
	xlabel(1(1)4, tposition(inside)) /// 
	ytitle("Market Share", size(large)) xtitle("Pricing Frequency", size(large)) legend(region(lcolor(white)) size(large) cols(1))
graph export "$FIGURES/plot_sim_shares_by_tech.pdf", replace


