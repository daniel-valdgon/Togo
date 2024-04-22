// checks to run on harmonized/standard datasets provided by the country teams

pause off 
/* -------------------------------------------------------------------------- */
/*          A. Household Data                                                 */
/* -------------------------------------------------------------------------- */

use "$temp\MPO_hh_${iso3}.dta", clear


/* ---- 1. Ids and weights -------------------------------------------------- */

cap noisily isid idh
if _rc {
	duplicates report idh
	count if idh >= .
}

cap noisily assert wgt > 0 & wgt < .
if _rc {
	sum wgt, d
	count if wgt >= .
}
pause


/* ---- 2. Other identifiers in space and time ------------------------------ */

//  a. each one should be a binary
foreach var of varlist wave_* region_* rural {
    cap noisily assert inlist(`var', 0, 1)
    if _rc {
	tab `var', m
    }
}

//  b. each hh assigned to one and only one "wave"
egen wcheck = rowtotal(wave_*)
cap noisily assert wcheck == 1
if _rc {
	tab wcheck, m	
	list idh wave_* if wcheck != 1
}

//  c. each hh assigned to one and only one "region"
egen rcheck = rowtotal(region_*)
cap noisily assert rcheck == 1
if _rc {
	tab rcheck, m
	list idh region_* if rcheck != 1
}
drop wcheck rcheck
pause


/* ---- 3. Household size and number of workers ----------------------------- */

cap noisily assert hhsize > 0 & hhsize < .
if _rc {
	tab hhsize, m
}

cap noisily assert nworker >= 0 & nworker <= hhsize
if _rc {
	tab nworker, m
	list idh nworker hhsize if nworker < . & nworker > hhsize
}
pause


/* ---- 4. Food and nonfood shares ------------------------------------------ */

//  a. nonfood 
cap noisily assert inrange(nfood_share, 0, 1)
if _rc {
	sum nfood_share
	count if nfood_share == .
}

//  b. food (all)
cap noisily assert inrange(food1_share, 0, 1)
if _rc {
	sum food1_share
	count if food1_share == .
}
cap noisily assert abs(nfood_share + food1_share - 1) < 0.0001 if nfood_share < . & food1_share < .
if _rc {
	list idh nfood_share food1_share if abs(nfood_share + food1_share - 1) > 0.0001 & nfood_share < . & food1_share < .
}

//  c. food (restricted)
cap noisily assert inrange(food2_share, 0, food1_share)
if _rc {
	sum food2_share
	count if food2_share == .
}

cap noisily assert inrange(food3_share, 0, food2_share)
if _rc {
	sum food3_share
	count if food3_share == .
}
pause


/* ---- 5. Consumption ------------------------------------------------------ */

cap noisily assert consumption > 0 & consumption < .
if _rc {
	sum consumption, d
	count if consumption >= .
}

cap noisily assert noncons_exp >= 0 & noncons_exp < .
if _rc {
	sum noncons_exp, d
	count if noncons_exp >= .
}

cap noisily assert nonlabor_inc >= 0 & nonlabor_inc < .
if _rc {
	sum nonlabor_inc d
	count if nonlabor_inc >= .
}
pause


/* ---- 6. Welfare measures ------------------------------------------------- */

//  a. for national poverty
cap noisily assert pcc > 0 & pcc < .
if _rc {
	sum pcc, d
	count if pcc >= .
}
cap noisily assert zref > 0 & zref < .
if _rc {
	sum zref
}
cap noisily assert zref == zref[1]
if _rc {
	sum zref
}
gen poor = 100 * (pcc < zref)
table rural [aw = wgt*hhsize], stat(mean poor)
// CHECK that this is the correct national poverty rate
drop poor

//  b. for international poverty
cap noisily assert ipcc > 0 & ipcc < .
if _rc {
	sum ipcc, d
	count if ipcc >= .
}
gen ipoor = 100 * (ipcc < 2.15)
table rural [aw = wgt*hhsize], stat(mean ipoor)
// CHECK that this is the correct international poverty rate
drop ipoor
pause


/* -------------------------------------------------------------------------- */
/*          B. Individual Data                                                */
/* -------------------------------------------------------------------------- */

use "$temp\MPO_ind_${iso3}.dta", clear

/* ---- 1. Ids and weights -------------------------------------------------- */

//  a. ids
cap noisily isid idh idi idj
if _rc {
	duplicates report idh idi idj
	count if idh >= .
	count if idi >= .
	cap noisily count if idj >= .
	cap noisily count if idj == ""
}

//  b. weights
cap noisily assert jwgt > 0 & jwgt < .
if _rc {
	sum jwgt, d
	count if jwgt >= .
}

bys idh idi: egen tot_wgt = sum(jwgt)
cap noisily assert abs(tot_wgt-1) < 0.00001
if _rc {
	sum tot_wgt, d
}
drop tot_wgt
pause


/* ---- 2. Age, sex and education ------------------------------------------- */

//  a. age
cap noisily assert inrange(age, 5, 105)
if _rc {
	tab age, m
}
cap noisily assert agesq == age^2

//  b. sex
cap noisily assert inlist(female, 0, 1)
if _rc {
	tab female, m
}

//  c. education (year)
cap noisily assert inrange(educy, 0, 30)
if _rc {
	tab educy, m
}
pause


/* ---- 3. Sector and employment status ------------------------------------- */

//  a. each one is a binary
foreach var of varlist sector_* empstat_* {
    di "checking `var'"
    cap noisily assert inlist(`var', 0, 1)
    if _rc {
	tab `var', m
    }
}

//  b. one and only one sector
egen scheck = rowtotal(sector_*)
cap noisily assert scheck == 1
if _rc {
	tab scheck, m
}

//  c. one and only one employment status
egen echeck = rowtotal(empstat_*)
cap noisily assert echeck == 1
if _rc {
	tab echeck, m
}
drop scheck echeck
pause


/* ---- 4. Hours worked ----------------------------------------------------- */

cap noisily assert hours > 0 & hours <= 5840
if _rc {
	sum hours, d
	count if hours >= .
}
pause



/* -------------------------------------------------------------------------- */
/*          C. Both Together                                                  */
/* -------------------------------------------------------------------------- */

use "$temp\MPO_ind_${iso3}.dta", clear
collapse (mean) age, by(idi idh)
collapse (count) numind = idi, by(idh)

//  a. same set of hhs
merge 1:1 idh using "$temp\MPO_hh_${iso3}.dta"
cap noisily assert inlist(_m, 2, 3)
if _rc {
	tab _m
}

//  b. number of workers
cap noisily assert nworker == 0 if _m == 2
if _rc {
	list idh nworker if _m == 2 & nworker != 0
}
cap noisily assert numind == nworker if _m == 3
pause
if _rc {
	list idh numind nworker if _m == 3 & numind != nworker
}
pause
