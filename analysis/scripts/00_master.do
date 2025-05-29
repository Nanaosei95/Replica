**********************
* OVERVIEW
*   This script generates tables and figures for the paper:
*       "Competition in Pricing Algorithms" (Zach Y. Brown and Alexander MacKay)
*   All data are stored in /analysis/data
*   All tables are outputted to /paper/tables
*   All figures are outputted to /paper/figures
* 
* SOFTWARE REQUIREMENTS
*   Analyses run on Windows using Stata version 16.1, R-3.6.3, and Matlab R2020b
**********************

* User must define three global macros in order to run the analysis:
* (1) "BASE" points to the project folder
* (2) "R_PATH" points to the folder containing the executables for R-3.6.3
* (3) "M_PATH" points to the raw data folder for large USASpending files

* Examples: [Uncomment and replace with correct directories]
//global BASE "C:/replication"
//global R_PATH "C:/Program Files/R/R-3.6.3/bin"
//global M_PATH "C:/Program Files/MATLAB/R2020b/bin"

* Run 
********************************************************************************
* Confirm that the globals for the project root directory and the R-3.6.1 executable have been defined
assert !missing("$BASE")
assert !missing("$R_PATH")
assert !missing("$M_PATH")

* Sub-folders defined automatically from project folder
global DATA "$BASE/analysis/data"
global RESULTS "$BASE/analysis/results"
global FIGURES "$BASE/paper/figures"
global TABLES "$BASE/paper/tables"
global SIM "$BASE/analysis/simulation"

* Use local packages
cap adopath - PERSONAL
cap adopath - PLUS
cap adopath - SITE
cap adopath - OLDPLACE
net set ado "$BASE/analysis/packages/Stata"
adopath ++ "$BASE/analysis/packages/Stata"

set scheme whitebg4
********************************************************************************

/*
*** Stata packages come pre-installed. If not working, can reinstall:
ssc install carryforward
net install ftools, from("http://fmwww.bc.edu/RePEc/bocode/f")
net install gr0034, from("http://www.stata-journal.com/software/sj8-2") // labmask
net install reghdfe, from("http://fmwww.bc.edu/RePEc/bocode/r")
net install regsave, from("http://fmwww.bc.edu/RePEc/bocode/r")
net install st0085_2, from("http://www.stata-journal.com/software/sj14-2") // esttab
net install tabout, from("http://fmwww.bc.edu/RePEc/bocode/t")
net install texsave, from("https://raw.githubusercontent.com/reifjulian/texsave/master") replace
ssc install tsspell
ado, from(PLUS)
ado, from("$BASE/analysis/packages/Stata")
*/

* Log session
cap mkdir "$BASE/analysis/logs/"
cap log off
local datetime : di %tcCCYY.NN.DD!_HH.MM.SS `=clock("$S_DATE $S_TIME", "DMYhms")'
local logfile "$BASE/analysis/logs/_log_all_`datetime'.smcl"
log using "`logfile'"
di "Begin date and time: $S_DATE $S_TIME"

clear all
set more off

********************************************************************************
*** Import and clean data
********************************************************************************
/*
* 01-05. Load and clean prices from five retailers
do "$BASE/analysis/scripts/01_clean_retailer_1.do"
do "$BASE/analysis/scripts/02_clean_retailer_2.do"
do "$BASE/analysis/scripts/03_clean_retailer_3.do"
do "$BASE/analysis/scripts/04_clean_retailer_4.do"
do "$BASE/analysis/scripts/05_clean_retailer_5.do"

* 06. Combine and prepare for analysis
do "$BASE/analysis/scripts/06_combine_data.do"
*/

********************************************************************************
*** Analysis
********************************************************************************

* 07. Summary statistics
do "$BASE/analysis/scripts/07_summary_stats.do"

* 08. Analysis
do "$BASE/analysis/scripts/08_analysis.do"

* 09. Price response to slower rivals
do "$BASE/analysis/scripts/09_price_response.do"

********************************************************************************
*** Learning simulation
********************************************************************************

* 10. Asymmetric learning simulations [R]
shell "$R_PATH\Rscript.exe" "$BASE/analysis/scripts/10_simple_learning_simulation_asymmetric.R" "$BASE" > "$BASE/analysis/logs/log_10.txt"

* 11. Symmetric learning simulation [R]
shell "$R_PATH\Rscript.exe" "$BASE/analysis/scripts/11_simple_learning_simulation_symmetric.R" "$BASE" > "$BASE/analysis/logs/log_11.txt"

* 12. Learning simulation plots
do "$BASE/analysis/scripts/12_learning_simulation_plots.do"


********************************************************************************
*** Calibration
********************************************************************************

cd "$SIM" // Change to directory so Matlab code can run

* 13. Run calibration [MATLAB]
shell "$M_PATH/matlab.exe" -nosplash -nodesktop -wait -r "run 'run_calibration.m'; quit" -logfile "$BASE/analysis/logs/log_13.txt"

* 14. Run merger simulation [MATLAB]
shell "$M_PATH/matlab.exe" -nosplash -nodesktop -wait -r "run 'run_merger_sim.m'; quit" -logfile "$BASE/analysis/logs/log_14.txt"

* 15. Plots for numerical oligopoly example
do "$BASE/analysis/scripts/15_plot_simulated_technology_premium.do"

* 16. Plot calibration output
do "$BASE/analysis/scripts/16_calibration_plots.do"

* 17. Test for shipping costs
do "$BASE/analysis/scripts/17_test_shipping_costs.do"

***
* End log
***
di "End date and time: $S_DATE $S_TIME"
log close

** EOF
