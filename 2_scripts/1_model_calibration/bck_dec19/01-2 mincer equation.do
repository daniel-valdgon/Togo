/*******************************************************************************

Estimating sectoral share at household level from Mincer regression
 country : 
 Data: EHCVM 2018/19
 Description : This program aims .....
 
 Authors: Mohamed Coulibaly/Sidi Mohamed Sawadogo, updated by Liz Foster
 Email: ssawadogo2@worldbank.org/mcoulibaly2@worldbank.org/efoster1@worldbank.org
 Last update : 5 Aug 2023
 
 Adapted by Kadidia Kone 
 Email:konkadidia19@gmail.com
 
********************************************************************************/

pause on


global Xind hours female age agesq educy sector_* empstat_* 
global Xhh rural region_* wave_* 
global Xs $Xind $Xhh

/* ---- 0. Construct household labor income --------------------------------- */

use "${temp}\MPO_hh_${iso3}.dta", clear

//  a. construct labor income
gen hhli = consumption + noncons_exp - nonlabor_income
sum hhli, d
replace hhli = 0 if hhli < 0 // just a few negatives

corr hhli consumption

gen logli = log10(hhli)
gen logdtot = log10(consumption)
tw scatter logli logdtot, aspect(1) msize(tiny) mcolor(%20) ///
    xlabel(5 "100k" 6 "1M" 7 "10M", grid gmin gmax) ylabel(5 "100k" 6 "1M" 7 "10M", grid gmin gmax) xsca(range(4.5 7.5)) ysca(range(4.5 7.5)) ///
    xtitle("consumption") ytitle("labor income") name(cons_li, replace)

label var hhli "Household labor/self-employment income"

//  b. construct total income
gen totincome = consumption + noncons_exp

tempfile li
save `li'



/* -------------------------------------------------------------------------- */
/*      A. Mincer model estimation for average household worker               */
/* -------------------------------------------------------------------------- */

/* ---- 1. Average worker characteristics ----------------------------------- */

//  a. average over individual data
use "${temp}\MPO_ind_${iso3}.dta", clear
merge m:1 idh using `li', keepusing(wgt) keep(match) nogen
tabstat sector_*
tabstat sector_* [aw = wgt]
collapse (mean) $Xind [pw = jwgt], by(idh)

//  b. merge in household-level variables
merge 1:1 idh using `li', keepusing(hhli wgt nworker $Xhh zref pcc) assert(match using) keep(match)

//  c. write results to spreadsheet
tabstat sector_* [aw = wgt*nworker], by(rural) save
tabstatmat A, nototal
*putexcel C28 = matrix(100*A')

gen nonpoor = pcc >= zref
tabstat sector_* [aw = wgt*nworker], by(nonpoor) save
tabstatmat A
*putexcel E28 = matrix(100*A')

//  c. log labor income per worker
gen double lnLx=ln(hhli/nworker)


/* ---- 2. Mincer equation -------------------------------------------------- */

sum $Xs
sum lnLx wgt nworker

//  a. regression
eststo Mincer : regress lnLx $Xs [pw=wgt*nworker]	
ereturn list
*putexcel F33 = `e(r2)'
predict res if e(sample) , res
gen eresid = exp(res) 
sum eresid [aw=wgt*nworker]
local duan = r(mean)
		
//  b. label Xs
label var hours "Mean hours worked"
lab var female "Share of female worker"
lab var age "Mean age of workers"
lab var agesq "Mean age squared of workers"
lab var educy "Average years of education of workers"
lab var sector_1 "Share of workers in Agriculture"
lab var sector_2 "Share of workers in Manufacture"
lab var sector_3 "Share of workers in Services"
lab var empstat_1 "Share of self-employee/own boss"
lab var empstat_2 "Share of salaried workers"
lab var empstat_3 "Share of other workers"
lab var rural "Live in rural areas"
lab var wave_1 "Interviewed during first wave"
		
//  c. estimation table
//esttab Mincer using "$temp\Mincer_${iso3}.tex", ar2 b(3) se(3) replace /*label*/ order ($Xs) keep($Xs) nobaselevels longtable booktabs star(* 0.10 ** 0.05 *** 0.01) title("Mincer equation for labor incomes per employed in $iso3")
		
//  d. estimation plot
qui coefplot Mincer, keep(hoursf female age agesq educy sector_1 sector_2 sector_3 empstat_1 empstat_2 empstat_3 rural) xline(0) title("Mincer regression results") byopts(xrescale) graphregion(col(white)) bgcol(white) eqlabels("labor incomes based", asequations)
*graph export "${graphs}\Mincer_$iso3.png", replace
*putexcel Y11 = image("${graphs}\Mincer_$iso3.png")

		
/* -------------------------------------------------------------------------- */
/*      B. Apply estimated coefficients to individual level data              */
/* -------------------------------------------------------------------------- */

/* ---- 1. Predict individual labor income ---------------------------------- */

//  a. indvidual data
use "${temp}\MPO_ind_${iso3}.dta", clear

//  b. impute missing values of Xs
sum $Xind

//  c. merge in hh level variables
merge m:1 idh using `li', keepusing($Xhh hhli) assert(match using) keep(match)

//  d. predict individual level labor income
estimates restore Mincer
predict double li    // predict individual labor income for each individual based on their characteristics and the coefficients from the average worker regression
replace li = exp(li)*`duan' // Duan's smearing estimator, see https://people.stat.sc.edu/hoyen/STAT704/Notes/Smearing.pdf
sum li

*********************************zCheck************************
//use "${temp}\MPO_hhli",clear 
//collapse li hhli, by(idh idi)

gen li_MPO=li
label var li_MPO "Labor income create initially in the MPO"
label var li "labor income ajusted to make respected equation"


egen sum_li=sum(li), by(idh)
by idh , sort: gen pid = _n
by idh : egen count = max(pid)
drop pid

format %9.0g li

replace li=hhli if count==1

egen maxi=max(count)

by idh : gen prop = li/sum_li if count>1
replace prop=round(prop, 0.00001)

egen pro=sum(prop), by(idh)

gen k=(1-pro)/count if pro!=1 & pro!=0
replace prop=prop+k if pro!=1 & pro!=0
egen pro1=sum(prop), by(idh)


gen l=(1-pro1)/count if pro!=1 & pro!=0
replace prop=prop+l if pro!=1 & pro!=0

egen pro2=sum(prop), by(idh)
replace li=hhli*prop if count>1
egen sum_li_v=sum(li), by(idh)

******************************************************************

/* ---- 2. Household shares from each sector + nonlabor --------------------- */

//  a. total predicted labor income from each sector
gen hhli_agric = li if sector_1 == 1	
gen hhli_manuf = li if sector_2 == 1	
gen hhli_serv  = li if sector_3 == 1	
egen hhli_hat = rsum(hhli_agric hhli_manuf hhli_serv)
sum hhli_*

preserve
collapse (sum) li li_MPO, by(idh idi branch csp rural female)

gen salaried=1 if csp==1|csp==2|csp==3|csp==4|csp==5|csp==6
gen self_employee=1 if csp==7|csp==8|csp==9|csp==10

gen double salaried_income=li if salaried==1,
gen double self_employee_income=li if self_employee==1

format %9.0g salaried_income self_employee_income

save "${temp}\labor_ind_${iso3}.dta", replace


restore

collapse (sum) hhli_* , by(idh)

//  b. merge in number of workers, total consumption etc
merge 1:1 idh using `li', keepusing(nworker totincome hhli) assert(match using) nogen
corr hhli_hat hhli
*putexcel F34 = `r(rho)'

//  c. construct shares from each sector
sum hhli totincome hhli_* 
foreach x in agric manuf serv { 
	gen     share_`x' = 0  if nworker == 0 /* whenever 0 worker within household */
	replace share_`x' = (hhli/totincome)*(hhli_`x'/(hhli_agric + hhli_manuf + hhli_serv)) if share_`x' == . 
}

//  d. percent of households with no labor income (no workers)
merge m:1 idh using `li', keepusing(wgt pcc zref rural) assert(match using) keep(match)
gen nonpoor = pcc >= zref
gen zero = nworker == 0
tabstat zero [aw = wgt], by(rural) save
tabstatmat A, nototal
*putexcel C41 = matrix(100*A')
tabstat zero [aw = wgt], by(nonpoor) save
tabstatmat A
*putexcel E41 = matrix(100*A')
	
//  e. construct share from nonlabor income
gen share_nli = 1 - (share_agric + share_manuf + share_serv)
sum share_*
sum share_nli, d
replace share_nli = 0 if share_nli < 0.00001
*assert abs(share_agric + share_manu + share_serv + share_nli - 1) < 0.0001


/* ---- 3. Write results to spreadsheet ------------------------------------- */

//  f. income from sectors
tabstat share_* [aw = wgt], by(rural) save
qui tabstatmat A, nototal
tabstat share_* [aw = wgt], by(nonpoor) save
qui tabstatmat B
matrix C = 100*A', 100*B'
*putexcel C37 = matrix(C)
	
save "${temp}\MPO_SectContrib_wsec_$iso3.dta", replace
	