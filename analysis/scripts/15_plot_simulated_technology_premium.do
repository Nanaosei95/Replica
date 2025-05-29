********************************************************************************
*** Figure 7
********************************************************************************

// Assume demand takes the following form (and constant marginal cost c)
//  p1 = a - bp1 - p2 -p3
//  p2 = a - bp2 - p1 -p3
//  p3 = a - bp3 - p1 -p2

clear all
set obs 3
gen pricing_tech = _n

gen pricing_tech_name = "Firm 1" if pricing_tech==1
replace pricing_tech_name = "Firm 2" if pricing_tech==2
replace pricing_tech_name = "Firm 3" if pricing_tech==3

gen pricing_tech2 = `"{fontface "Palatino": {&gamma}{sub:1}}"' if pricing_tech==1
replace pricing_tech2 = `"{fontface "Palatino": {&gamma}{sub:2}}"' if pricing_tech==2
replace pricing_tech2 = `"{fontface "Palatino": {&gamma}{sub:3}}"' if pricing_tech==3
encode pricing_tech2, gen(pricing_tech_lbl)


* Parameters
gen a = 1/2
gen c = 0

// Bertrand Nash
gen price_bn = (2 - 2*a)^(-1)

// Pricing Algorithms
gen price_pa = (8 + 8*a - a^3)/(16 - 24*a^2 - 8*a^3 + 2*a^4) if pricing_tech == 1
replace price_pa =  -1/2*((2 + a)*(1 + (a*(8 + 8*a - a^3))/(16 - 24*a^2 - 8*a^3 + 2*a^4)))/(-2 + a^2) if pricing_tech == 2
replace price_pa = (1 + a*((8 + 8*a - a^3)/(16 - 24*a^2 - 8*a^3 + 2*a^4) - ((2 + a)*(1 + (a*(8 + 8*a - a^3))/(16 - 24*a^2 - 8*a^3 + 2*a^4)))/(2*(-2 + a^2))))/2 if pricing_tech == 3

// Merger under BN
gen price_bn_m12 = (2 + a)/(4 - 4*a - 2*a^2) if pricing_tech == 1 | pricing_tech == 2
replace price_bn_m12 = (2 - 2*a - a^2)^(-1) if pricing_tech == 3

// Merger 1/2 under pricing algos
gen price_pa_m12 = -1/4*(2 + a)/(-1 + a + a^2) if pricing_tech == 1 | pricing_tech == 2
egen temp_price = max(price_pa_m12)
replace price_pa_m12 = (1 + a*(temp_price + temp_price))/2 if pricing_tech == 3
drop temp_price

gen price_pa_m23 =  -1/2*1/(-1 + a + a^2) if pricing_tech == 1 
egen temp_price = max(price_pa_m23)
replace price_pa_m23 = (1 + a*temp_price)/(2 - 2*a) if pricing_tech == 3 | pricing_tech == 2
drop temp_price

label var price_pa "Algorithmic Pricing"
label var price_bn "Bertrand"

label var price_bn_m12 "Bertrand Merger (1-2)"
label var price_pa_m12 "Slow Merger (1-2)"
label var price_pa_m23 "Fast Merger (2-3)"

scatter price_pa price_bn pricing_tech_lbl, mcolor(black gs11) msymbol(O O) connect(l l) lpattern(solid dot) ///
	xscale(r(.75 3.25)) yscale(r(.9 1.5)) ylabel(.9(.1)1.5, tposition(inside) angle(horizontal) format(%4.1f))  ///
	xlabel(1(1)3, tposition(inside)) ytitle("Price", size(large)) xtitle("Firm", size(large) margin(small)) scheme(s1mono) ///
		legend(cols(2) region(lstyle(none)) size(large))
graph export "$FIGURES/price_3firm.pdf", replace

scatter price_pa_m12 price_pa_m23 price_bn_m12 pricing_tech_lbl, mcolor(black gs6 gs11) msymbol(O O 0) connect(l l l) lpattern(solid dash dot) /// 
	xscale(r(.75 3.25)) yscale(r(.9 2.6)) ylabel(1(.3)2.5, tposition(inside) angle(horizontal) format(%4.1f))  ///
	xlabel(1(1)3, tposition(inside)) ytitle("Price", size(large)) xtitle("Firm", size(large) margin(small)) scheme(s1mono) ///
		legend(cols(2) order(1 3 2) region(lstyle(none)) size(large))
graph export "$FIGURES/price_3firm_merger.pdf", replace



********************************************************************************
*** Table 9
********************************************************************************

clear all
set obs 3

* Demand parameter
gen a = 0.3 if _n==1
replace a = 0.4 if _n==2
replace a = 0.5 if _n==3

gen c = 0

// Bertrand Nash
gen price_bn = (2 - 2*a)^(-1)
label var price_bn "Bertrand Nash"

gen q_bn = 1 - price_bn + a*(price_bn + price_bn)
gen profit_bn = price_bn*q_bn

// Collusive Equilibrium
gen price_collus = (3 + c - 2*a*c)/(6 - 12*a)
label var price_collus "Collusive"

gen q_collus = 1 - price_collus + a*(price_collus + price_collus)

// Pricing Algorithms
gen price_pa_1 = (8 + 8*a - a^3)/(16 - 24*a^2 - 8*a^3 + 2*a^4)
gen price_pa_2 = -1/2*((2 + a)*(1 + (a*(8 + 8*a - a^3))/(16 - 24*a^2 - 8*a^3 + 2*a^4)))/(-2 + a^2)
gen price_pa_3 = (1 + a*((8 + 8*a - a^3)/(16 - 24*a^2 - 8*a^3 + 2*a^4) - ((2 + a)*(1 + (a*(8 + 8*a - a^3))/(16 - 24*a^2 - 8*a^3 + 2*a^4)))/(2*(-2 + a^2))))/2
label var price_pa_1 "Firm 1 (slowest)"
label var price_pa_2 "Firm 2"
label var price_pa_3 "Firm 3 (fastest)"

gen q_pa_1 = 1 - price_pa_1 + a*(price_pa_2 + price_pa_3)
gen q_pa_2 = 1 - price_pa_2 + a*(price_pa_1 + price_pa_3)
gen q_pa_3 = 1 - price_pa_3 + a*(price_pa_1 + price_pa_2)

gen profit_pa_1 = price_pa_1*q_pa_1
gen profit_pa_2 = price_pa_2*q_pa_2
gen profit_pa_3 = price_pa_3*q_pa_3
summ profit_pa_1 profit_pa_2 profit_pa_3
summ profit_pa_1 profit_pa_2 profit_pa_3 if a==0.25

// Merger under BN
gen price_12_bnmerger12 = (2 + a)/(4 - 4*a - 2*a^2)
gen price_3_bnmerger12 = (2 - 2*a - a^2)^(-1)
gen q_12_bnmerger12 = 1 - price_12_bnmerger12 + a*(price_12_bnmerger12 + price_3_bnmerger12)
gen q_3_bnmerger12 = 1 - price_3_bnmerger12 + a*(price_12_bnmerger12 + price_12_bnmerger12)
gen profit_12_bnmerger12 = 2*price_12_bnmerger12*q_12_bnmerger12
gen profit_3_bnmerger12 = price_3_bnmerger12*q_3_bnmerger12

// Merger 1/2 under pricing algos
gen price_12_pamerger12 = -1/4*(2 + a)/(-1 + a + a^2)
label var price_12_pamerger12 "Firm 1/2 Post-Merger"
gen price_3_pamerger12 = (1 + a*(price_12_pamerger12 + price_12_pamerger12))/2
label var price_3_pamerger12 "Firm 3 Post-Merger"
gen q_12_pamerger12 = 1 - price_12_pamerger12 + a*(price_12_pamerger12 + price_3_bnmerger12)
gen q_3_pamerger12 = 1 - price_3_pamerger12 + a*(price_12_pamerger12 + price_12_pamerger12)

gen profit_12_pamerger12 = 2*price_12_pamerger12*q_12_pamerger12
gen profit_3_pamerger12 = price_3_pamerger12*q_3_pamerger12

gen price_shareweighted_pamerger12 = (2*price_12_pamerger12*q_12_pamerger12 + price_3_pamerger12*q_3_pamerger12)/ (2*q_12_pamerger12+q_3_pamerger12)
label var price_shareweighted_pamerger12 "1/2 Merger Under Algorithmic Pricing"
summ price_12_pamerger12 price_3_pamerger12 price_shareweighted_pamerger12

// Merger 2/3 under pricing algos
gen price_1_pamerger23 = -1/2*1/(-1 + a + a^2)
label var price_1_pamerger23 "Firm 1 Post-Merger"
gen price_23_pamerger23 = (1 + a*price_1_pamerger23)/(2 - 2*a)
label var price_23_pamerger23 "Firm 2/3 Post-Merger"
gen q_1_pamerger23 = 1 - price_1_pamerger23 + a*(price_23_pamerger23 + price_23_pamerger23)
gen q_23_pamerger23 = 1 - price_23_pamerger23 + a*(price_1_pamerger23 + price_23_pamerger23)

gen profit_1_pamerger23 = price_1_pamerger23*q_1_pamerger23
gen profit_23_pamerger23 = 2*price_23_pamerger23*q_23_pamerger23

gen price_shareweighted_pamerger23 = (price_1_pamerger23*q_1_pamerger23 + 2*price_23_pamerger23*q_23_pamerger23)/ (q_1_pamerger23+2*q_23_pamerger23)
label var price_shareweighted_pamerger23 "2/3 Merger Under Algorithmic Pricing"

summ price_1_pamerger23 price_23_pamerger23 price_shareweighted_pamerger23

gen profit_pa_12 = profit_pa_1+profit_pa_2

* Fast firm merger (2/3)
label var price_pa_1 "Firm 1 Pre-Merger"
gen profit_pa_23 = profit_pa_2+profit_pa_3


* Bertrand Panel 
eststo clear
quietly estpost tabstat price_bn price_bn price_bn profit_bn profit_bn profit_bn price_3_bnmerger12 price_12_bnmerger12 profit_3_bnmerger12 profit_12_bnmerger12, by(a)
esttab using "$TABLES/table_3firm_bn.tex", frag cells("price_bn(fmt(2)) price_bn(fmt(2)) price_bn(fmt(2)) profit_bn(fmt(2)) profit_bn(fmt(2)) profit_bn(fmt(2)) price_3_bnmerger12(fmt(2)) price_12_bnmerger12(fmt(2)) profit_3_bnmerger12(fmt(2)) profit_12_bnmerger12(fmt(2))" ) noobs nomtitle nonumber nodep nomti nolines varlabels(1 "0.3" 2 "0.4" 3 "0.5") collabels(none) varwidth(4) drop(Total) tex replace

* Algorithmic Competition Panel
eststo clear
quietly estpost tabstat price_pa_1 price_pa_2 price_pa_3 profit_pa_1 profit_pa_2 profit_pa_3 price_1_pamerger23 price_23_pamerger23 profit_1_pamerger23 profit_23_pamerger23 price_12_pamerger12 price_3_pamerger12 profit_12_pamerger12 profit_3_pamerger12, by(a)
esttab using "$TABLES/table_3firm_pa.tex", frag cells("price_pa_1(fmt(2)) price_pa_2(fmt(2)) price_pa_3(fmt(2)) profit_pa_1(fmt(2)) profit_pa_2(fmt(2)) profit_pa_3(fmt(2)) price_1_pamerger23(fmt(2)) price_23_pamerger23(fmt(2)) profit_1_pamerger23(fmt(2)) profit_23_pamerger23(fmt(2)) price_12_pamerger12(fmt(2)) price_3_pamerger12(fmt(2)) profit_12_pamerger12(fmt(2)) profit_3_pamerger12(fmt(2))" ) noobs nomtitle nonumber nodep nomti  nolines varlabels(1 "0.3" 2 "0.4" 3 "0.5") collabels(none) varwidth(4) drop(Total) tex replace


********************************************************************************
*** Figure 11 (Appendix)
********************************************************************************
clear all
set obs 100

* Demand parameter
gen a = (_n-1) / (_N)
replace a = 1/2 - a/2
keep if inrange(a,0.25,0.5)

gen c = 0



// Bertrand Nash
gen price_bn = (2 - 2*a)^(-1)
label var price_bn "Bertrand-Nash"

gen q_bn = 1 - price_bn + a*(price_bn + price_bn)
gen profit_bn = price_bn*q_bn

// Collusive Equilibrium
gen price_collus = (3 + c - 2*a*c)/(6 - 12*a)
label var price_collus "Collusive"

gen q_collus = 1 - price_collus + a*(price_collus + price_collus)


// Pricing Algorithms
gen price_pa_1 = (8 + 8*a - a^3)/(16 - 24*a^2 - 8*a^3 + 2*a^4)
gen price_pa_2 = -1/2*((2 + a)*(1 + (a*(8 + 8*a - a^3))/(16 - 24*a^2 - 8*a^3 + 2*a^4)))/(-2 + a^2)
gen price_pa_3 = (1 + a*((8 + 8*a - a^3)/(16 - 24*a^2 - 8*a^3 + 2*a^4) - ((2 + a)*(1 + (a*(8 + 8*a - a^3))/(16 - 24*a^2 - 8*a^3 + 2*a^4)))/(2*(-2 + a^2))))/2
label var price_pa_1 "Firm 1 (Slowest)"
label var price_pa_2 "Firm 2"
label var price_pa_3 "Firm 3 (Fastest)"

gen q_pa_1 = 1 - price_pa_1 + a*(price_pa_2 + price_pa_3)
gen q_pa_2 = 1 - price_pa_2 + a*(price_pa_1 + price_pa_3)
gen q_pa_3 = 1 - price_pa_3 + a*(price_pa_1 + price_pa_2)

gen profit_pa_1 = price_pa_1*q_pa_1
gen profit_pa_2 = price_pa_2*q_pa_2
gen profit_pa_3 = price_pa_3*q_pa_3
summ profit_pa_1 profit_pa_2 profit_pa_3
summ profit_pa_1 profit_pa_2 profit_pa_3 if a==0.25


gen price_shareweighted_pa_12 = (price_pa_1*q_pa_1 + price_pa_2*q_pa_2)/ (q_pa_1 + q_pa_2)
label var price_shareweighted_pa_12 "Firm 1/2 Pre-Merger"
gen price_shareweighted_pa_23 = (price_pa_3*q_pa_3 + price_pa_2*q_pa_2)/ (q_pa_3 + q_pa_2)
label var price_shareweighted_pa_23 "Firm 2/3 Pre-Merger"


gen price_shareweighted_pa = (price_pa_1*q_pa_1 + price_pa_2*q_pa_2 + price_pa_3*q_pa_3)/ (q_pa_1 + q_pa_2 + q_pa_3)
label var price_shareweighted_pa "Pre-Merger Under Algorithmic Pricing"


twoway (line price_bn a, lp("-") color(gs11) ) ///
	(line price_pa_1 a, color(gs12) lp(medthick) ) ///
	(line price_pa_2 a, color(gs10) lw(medthick)) ///
	(line price_pa_3 a, color(black) lp(solid) lw(medthick ) ) , ///
		ytitle("Price", size(medium)) xtitle("Inverse Product Differentiation ({it:b})", size(medium)) ///
		ylabel(, tposition(inside) angle(horizontal) format(%4.1f) labsize(medium)) ///
		xlabel(, tposition(inside) labsize(medium)) scheme(s1mono) ///
		legend(cols(2) region(lstyle(none)))

graph export "$FIGURES/plot_sim_technology_premium.pdf", replace



// Merger under BN
gen price_12_bnmerger12 = (2 + a)/(4 - 4*a - 2*a^2)
gen price_3_bnmerger12 = (2 - 2*a - a^2)^(-1)
gen q_12_bnmerger12 = 1 - price_12_bnmerger12 + a*(price_12_bnmerger12 + price_3_bnmerger12)
gen q_3_bnmerger12 = 1 - price_3_bnmerger12 + a*(price_12_bnmerger12 + price_12_bnmerger12)

gen price_shareweighted_bnmerger12 = (2*price_12_bnmerger12*q_12_bnmerger12 + price_3_bnmerger12*q_3_bnmerger12)/ (2*q_12_bnmerger12+q_3_bnmerger12)
label var price_shareweighted_bnmerger12 "Merger Under Bertrand Nash"

summ price_12_bnmerger12 price_3_bnmerger12 price_shareweighted_bnmerger12

// Merger 1/2 under pricing algos
gen price_12_pamerger12 = -1/4*(2 + a)/(-1 + a + a^2)
label var price_12_pamerger12 "Firm 1/2 Post-Merger"
gen price_3_pamerger12 = (1 + a*(price_12_pamerger12 + price_12_pamerger12))/2
label var price_3_pamerger12 "Firm 3 Post-Merger"
gen q_12_pamerger12 = 1 - price_12_pamerger12 + a*(price_12_pamerger12 + price_3_bnmerger12)
gen q_3_pamerger12 = 1 - price_3_pamerger12 + a*(price_12_pamerger12 + price_12_pamerger12)

gen profit_12_pamerger12 = 2*price_12_pamerger12*q_12_pamerger12
gen profit_3_pamerger12 = price_3_pamerger12*q_3_pamerger12

gen price_shareweighted_pamerger12 = (2*price_12_pamerger12*q_12_pamerger12 + price_3_pamerger12*q_3_pamerger12)/ (2*q_12_pamerger12+q_3_pamerger12)
label var price_shareweighted_pamerger12 "1/2 Merger Under Algorithmic Pricing"

summ price_12_pamerger12 price_3_pamerger12 price_shareweighted_pamerger12


// Merger 2/3 under pricing algos
gen price_1_pamerger23 = -1/2*1/(-1 + a + a^2)
label var price_1_pamerger23 "Firm 1 Post-Merger"
gen price_23_pamerger23 = (1 + a*price_1_pamerger23)/(2 - 2*a)
label var price_23_pamerger23 "Firm 2/3 Post-Merger"
gen q_1_pamerger23 = 1 - price_1_pamerger23 + a*(price_23_pamerger23 + price_23_pamerger23)
gen q_23_pamerger23 = 1 - price_23_pamerger23 + a*(price_1_pamerger23 + price_23_pamerger23)

gen profit_1_pamerger23 = price_1_pamerger23*q_1_pamerger23
gen profit_23_pamerger23 = 2*price_23_pamerger23*q_23_pamerger23

gen price_shareweighted_pamerger23 = (price_1_pamerger23*q_1_pamerger23 + 2*price_23_pamerger23*q_23_pamerger23)/ (q_1_pamerger23+2*q_23_pamerger23)
label var price_shareweighted_pamerger23 "2/3 Merger Under Algorithmic Pricing"

summ price_1_pamerger23 price_23_pamerger23 price_shareweighted_pamerger23


* post-merger prices for Bertrand, merged firm (fast), merged firm (slow), unmerged rival (fast), unmerged rival (slow)
label var price_3_bnmerger12 "Unmerged Rival: Bertrand"
label var price_12_bnmerger12 "Merged Firm: Bertrand"
label var price_23_pamerger23 "Merged Firm: Fast Merger"
label var price_12_pamerger12 "Merged Firm: Slow Merger"
label var price_1_pamerger23 "Unmerged Rival: Fast Merger"
label var price_3_pamerger12 "Unmerged Rival: Slow Merger"
twoway (line price_12_bnmerger12 a, color(navy%40) lp(solid) ) ///
	(line price_3_bnmerger12 a, color(navy%40) lp("-")  ) ///
	(line price_23_pamerger23 a, color(maroon%60) lp(solid)) ///
	(line price_1_pamerger23 a, color(maroon%60) lp("-")) ///
	(line price_12_pamerger12 a, color(black) lp(solid)) ///
	(line price_3_pamerger12 a, color(black) lp("-") ) , ///
			ytitle("Price", size(medium)) xtitle("Inverse Product Differentiation ({it:b})", size(medium)) ///
		ylabel(, tposition(inside) angle(horizontal) format(%4.1f) labsize(medium)) ///
		xlabel(, tposition(inside) labsize(medium)) scheme(s1mono) ///
		legend(cols(2) size(*0.85) region(lstyle(none)))
graph export "$FIGURES/price_3firm_post_merger.pdf", replace
