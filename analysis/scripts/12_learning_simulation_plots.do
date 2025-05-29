clear all

use "$BASE/analysis/results/learning_asymmetric.dta", clear
assert b1 == 0
summ stable1 stable2
gen x1 = _n/_N*2
gen x2 = _n/_N + .5
gen r1 = 1/2 + 1/2*x1
gen r2 = -1 + 2*x2

twoway (scatter price2 price1, mlcolor(maroon%06) mfcolor(maroon%03)) ///
	(pci .5 0 1.333 1.667, lcolor(black%10)) ///
	(pci 0 .5 1.667 1.333, lcolor(black%10)) ///
	, ytitle("Price (Firm 2)") xtitle("Price (Firm 1)") ///
	xlabel(0(0.25)2) ylabel(0(0.25)2) ysize(3) xsize(3) legend(off)
graph export "$FIGURES/equilibrium_selection_asymmetric.pdf", replace

use "$BASE/analysis/results/learning_symmetric.dta", clear
summ stable1 stable2
gen x1 = _n/_N*2
gen x2 = _n/_N + .5
gen r1 = 1/2 + 1/2*x1
gen r2 = -1 + 2*x2
twoway (scatter price2 price1, mlcolor(maroon%06) mfcolor(maroon%03)) ///
	(pci .5 0 1.333 1.667, lcolor(black%10)) ///
	(pci 0 .5 1.667 1.333, lcolor(black%10)) ///
	, ytitle("Price (Firm 2)") xtitle("Price (Firm 1)") ///
	xlabel(0(0.25)2) ylabel(0(0.25)2) ysize(3) xsize(3) legend(off)
graph export "$FIGURES/equilibrium_selection_symmetric.pdf", replace
	

