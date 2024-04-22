 /*******************************************************************************
 Data preparation for MPO Tool
 country : any from EHCVM 2018/19
 Data: EHCVM 2018/19
 Description : This program aims at preparing dataset that would be used for Macro Poverty Outlook tool and adapted for CCDR Togo
 Authors: Mohamed Coulibaly/Sidi Mohamed Sawadogo, revised by Liz Foster/ adapted by Kadidia Koné
 Email: ssawadogo2@worldbank.org/mcoulibaly2@worldbank.org/efoster1@worldbank.org/ konkadidia19@gmail.com
 Last update : Oct 2023

Creates two datasets, one household level and one individual level

********************************************************************************/

pause off


/* -------------------------------------------------------------------------- */
/*                                                                            */
/*          I. HOUSEHOLD LEVEL                                                */
/*                                                                            */
/* -------------------------------------------------------------------------- */

/* -------------------------------------------------------------------------- */
/*      A. Food Share of Consumption, 3 Different Ways                        */
/* -------------------------------------------------------------------------- */

// for creating household specific inflation rates
// divide consumption in nonfood share, food share subject to inflation and food
// share not subject to inflation

/* ---- 1. Prepare data ----------------------------------------------------- */

use "$data\ehcvm_conso_tgo2018.dta", clear

//  a. grains vs. other foods vs. nonfood by source

recode codpr (1/15 = 1 "grain") (16/152 = 2 "other food") (153/max = 3 "nonfood"), gen(class) // need to check this for other countries
lab var class "type of consumption item"
cap numlabel codprl, add
tab codpr if modep == 2 [aw = hhweight*depan], sort
table class modep [aw = hhweight], stat(total depan)

//  b. total expenditure over household by type of item and source
replace depan=abs(depan) if depan<0
collapse (sum) depan, by(hhid codpr modep hhweight)
isid hhid codpr modep 
reshape wide depan, i(hhid codpr) j(modep)

//  c. own production vs. other
rename depan2 ownproduct        // own production
egen market = rowtotal(depan*)  // market + gifts/in kind payments + use value + imputed rent
drop depan*

//  d. reshape to have different variables by type of item
reshape wide  market ownproduct, i(hhid) j(codpr)
// have 6 variables: market1 (grains), market2 (other food), market3 (nonfood), ownproduct1 (grains), ownproduct2 (other food), ownproduct3 (nonfood from own production = 0)
sum market* ownproduct*
assert ownproduct3 == .
// (not dropping, EHCVM round 2 has own production of firewood)


/* ---- 2. Define types of consumption and shares --------------------------- */

*order market* ownproduct*

//  a. divide consumption up different ways
egen totdepan = rowtotal(market* ownproduct*)                    // total consumption

//all nonfood
egen allnfood = rowtotal(ownproduct201-market843)
// all nonfood 

//all food
egen allfood = rowtotal(ownproduct1-market152)  // all food

order ownproduct* 

egen ownfood = rowtotal(ownproduct1-ownproduct152)                 // food from own production

egen owngrain = rowtotal(ownproduct1 ownproduct2 ownproduct3 ownproduct4 ownproduct5 ownproduct6 ownproduct7 ownproduct8 ownproduct10 ownproduct11 ownproduct12 ownproduct13 ownproduct14 ownproduct15 ) // grain (likely stored) from own production



//  b. define share subject to food inflation three different ways
gen food1_share = allfood/totdepan // consider all food as subject to food price inflation
gen nfood_share = 1 - food1_share
gen food2_share = (allfood - owngrain)/totdepan // consider just own produced grain exempt from inflation
gen food3_share = (allfood - ownfood)/totdepan // consider all own produced food exempt from inflation
replace food3_share=0 if food3_share
sum food?_share 

//  c. save
*keep hhid food?_share nfood_share
order nfood_share food?_share
lab var nfood "share of consumption from nonfood"
lab var food1_share "share of consumption from food"
lab var food2_share "share of consumption from food EXCEPT own produced grains"
lab var food3_share "share of consumption from food EXCEPT all own production"
rename hhid idh
tempfile shares
save `shares'


/* -------------------------------------------------------------------------- */
/*      B. Income from Non Labor Sources                                      */
/* -------------------------------------------------------------------------- */

/* ---- 1. Remittances received --------------------------------------------- */

use "$data\s13a_2_me_tgo2018.dta", clear
gen double hhid = 1000*grappe + menage
if "${iso3}" == "CIV" | "${iso3}" == "TGO" | "${iso3}" == "GIN" replace hhid = 100 * grappe + menage
if "${iso3}" == "GNB" replace hhid = 100 * grappe + menage if menage < 10
des s13aq17a s13aq17b
		
//  a. annualize
tab s13aq17b
recode s13aq17b (1 = 12) (2 = 4) (3 = 2) (4 5 = 1), gen(factor)
gen remit_received = s13aq17a * factor

//  b. look at distribution
sum remit_received, detail
gen logremit = log10(remit_received)
histogram logremit, normal name(remitrec, replace) // upper tail is actually nicely log normal
		
//  c. Winsorize values at 99%
winsor2 remit_received if remit_received != 0 , replace cuts(0 99)
sum remit_received, d
		
//  d. collapse to household level
collapse (sum) remit_received, by(hhid)

tempfile s13a
save `s13a'


/* ---- 2. Remittances sent ------------------------------------------------- */

use "$data\s13b_2_me_tgo2018.dta", clear
gen double hhid = 1000*grappe + menage
if "${iso3}" == "CIV" | "${iso3}" == "TGO" | "${iso3}" == "GIN" replace hhid = 100 * grappe + menage
if "${iso3}" == "GNB" replace hhid = 100 * grappe + menage if menage < 10
cap noisily des s13bq34a
cap noisily des s13bq34b
cap noisily des s13bq28b

//  a. annualize
cap noisily tab s13bq34b vague
cap noisily tab s13bq28b vague
if "${iso3}" == "BFA" || "${iso3}" == "CIV" {
    tab s13bq28b vague, m
    replace s13bq34b = s13bq28b if vague == 1
}
if "${iso3}" == "TCD" {
    gen s13bq34b = s13bq28b // stored is this variable for all hhs in Tchad
}

recode s13bq34b (1 = 12) (2 = 4) (3 = 2) (4 5 = 1), gen(factor)
gen remit_sent = s13bq34a * factor
		
//  b. look at distribution
sum remit_sent, detail
gen logremit = log10(remit_sent)
histogram logremit, normal name(remitsent, replace) // upper tail is actually nicely log normal

//  c. Winsorize values at 99%
winsor2 remit_sent if remit_sent != 0, replace cuts(0 99)
sum remit_sent, detail
		
//  d. collapse to household level
bys hhid: assert menage == menage[1]
bys hhid: assert grappe == grappe[1]

gen remit_sent_int=remit_sent if s13bq31==11 | s13bq31<3
collapse (sum) remit_sent remit_sent_int, by(hhid grappe menage)

tempfile s13b
save `s13b' 


/* ---- 3. Other sources of income ----------------------------------------- */

use "$data\s05_me_tgo2018.dta", clear
gen double hhid = 1000*grappe + menage 
if "${iso3}" == "CIV" | "${iso3}" == "TGO" | "${iso3}" == "GIN" replace hhid = 100 * grappe + menage
if "${iso3}" == "GNB" replace hhid = 100 * grappe + menage if menage < 10
des s05q02 s05q04 s05q06 s05q08 s05q10 s05q12

//  a. income from government programs (pension etc)
egen ytrg = rowtotal(s05q02 s05q04 s05q06 s05q08)
label var ytrg "Income from government. transfers"

sum ytrg, d
gen logytrg = log10(ytrg)
histogram logytrg, normal name(govtrans, replace)
winsor2 ytrg if ytrg != 0, replace cuts(0 99)
sum ytrg, d
			
//  b. other nonlabor income (rental, other)
egen ynl = rowtotal(s05q10 s05q12 s05q14)
label var ynl "Non-labor income"
		
sum ynl, d
gen logynl = log10(ynl)
histogram logynl, normal name(miscy, replace)
winsor2 ynl if ynl != 0, replace cuts(0 99)
sum ynl, d
	
collapse (sum) ytrg ynl, by(hhid)
		
tempfile s05
save `s05'


/* --- 4. Number of workers ------------------------------------------------- */

use "${data}\ehcvm_individu_tgo2018.dta", clear
cap noisily tab resid, sum(resid)
if !_rc {
    keep if resid == 1 // keep only hh members for datasets with that distinction
}
gen worker = (age >= 15 & age < 65) & inlist(activ12m, 1, 2)
count if worker
pause
tab worker, m
collapse (sum) nworker = worker, by(hhid)
tab nworker, m
rename hhid idh

tempfile nworker
save `nworker'



/* -------------------------------------------------------------------------- */
/*      C. All Household Variables                                            */
/* -------------------------------------------------------------------------- */

use "$data\ehcvm_welfare_tgo2018.dta", clear


/* ---- 1. General identifiers ---------------------------------------------- */

*** Country
*if "${iso3}" == "GIN"  gen country = "GIN"
*label var country "Country"

	
**Wave of the servey
tab vague, gen(wave_)
		
*** Household ID
gen double idh = hhid
isid hhid
isid idh
label var idh "Household ID"
	
*** Household weight
gen wgt  = hhweight
label var wgt "Household weight"
	
*** Household size
cap gen hhsize  = hhsize 
label var hhsize "Household size"

*** Region
cap gen region = region
label var region "Region"
tab region, gen(region_)

** Rural
recode milieu (1 = 0)(2 = 1), gen(rural)
label define rural 0 "Urban" 1 "Rural", replace
label value  rural rural
label var rural "Rural"


/* ---- 2. Welfare aggregates ----------------------------------------------- */
	
*** Comsumption per capita
gen pcc = pcexp // this is for national poverty
label var pcc "Per capita consumption for national poverty"

gen ipcc = dtot / hhsize /365 $def_temp_prix / $icp / $cpi // this will be for international poverty, NOT spatially deflated, realigned temporal deflators, converted to 2017 PPP USD
gen ipoor = ipcc < 2.15
sum dtot hhsize /*def_temp_prix*/
di $icp
di $cpi
sum ipoor [aw = hhweight * hhsize]
label var ipcc "Per capita consumption for international poverty (2017 PPP USD)"
pause


/* ---- 3. Construct nonlabor income ---------------------------------------- */

*** Assumption : C(consumption) + S(Transfers sent) = L(Labor income) + NL(non-labor income)	
*** thus L = C + S - NL

//  a. merge in transfers sent
merge 1:1 hhid using `s13b'
cap noisily assert inlist(_m, 1, 3)
if _rc {
    pause
    drop if _m == 2
}
replace remit_sent = 0 if _m == 1 // didn't send any
drop _m

//  b. merge in transfers received
merge 1:1 hhid using `s13a'
cap noisily assert inlist(_m, 1, 3)
if _rc {
    pause
    drop if _m == 2
}
replace remit_received = 0 if _m == 1 // didn't receive any
drop _m

//  c. merge in misc income sources
merge 1:1 hhid using `s05'
cap noisily assert _m == 3 
if _rc {
   pause 
   drop if _m == 2
   replace ytrg = 0 if _m == 1
   replace ynl  = 0 if _m == 1
}

//  d. total non-consumption expenditures
gen noncons_exp = remit_sent

//  e. total non-labor income
gen nonlabor_income  = remit_received + ytrg + ynl

//  f. total nominal consumption
gen consumption = dtot


/* ---- 4. Merge in shares and save ----------------------------------------- */

keep idh wave_* rural region_* hhsize pcc ipcc wgt zref noncons_exp nonlabor_income consumption ynl ytrg remit_sent remit_received

order idh wgt wave_* region_* rural hhsize consumption noncons_exp nonlabor_income pcc zref ipcc 

merge 1:1 idh using `nworker' 
cap noisily assert _m == 3 
if _rc {
    pause
    drop if _m == 2
    drop _m
}

drop _m
order nworker, after(hhsize)

merge 1:1 idh using `shares'
cap noisily assert _m == 3
if _rc {
    pause
    drop if _m == 2
    drop _m
}
drop _m
order nfood_share food?_share, after(nworker)


/* ---- 5. Checks ---------------------------------------------------------- */

isid idh
foreach var of varlist wave_* region_* rural {
    assert inlist(`var', 0, 1)
}
egen wcheck = rowtotal(wave_*)
assert wcheck == 1
egen rcheck = rowtotal(region_*)
assert rcheck == 1
drop wcheck rcheck
assert hhsize > 0 & hhsize < .
cap noisily assert nworker >= 0 & nworker <= hhsize
if _rc {
    list idh nworker hhsize if nworker < 0 | nworker > hhsize
}
assert inrange(nfood_share, 0, 1)
assert inrange(food1_share, 0, 1)
assert abs(nfood_share + food1_share - 1) < 0.0001
assert inrange(food2_share, 0, food1_share)
assert inrange(food3_share, 0, food2_share)
assert pcc > 0 & pcc < .
assert ipcc > 0 & ipcc < .
assert wgt > 0 & wgt < .
assert zref > 0 & zref < .
assert zref == zref[1]
assert noncons_exp >= 0 & noncons_exp < .
assert nonlabor_income >= 0 & nonlabor_income < .
assert consumption >= 0 & consumption < .

save "$temp\MPO_hh_TGO.dta", replace



/* -------------------------------------------------------------------------- */
/*                                                                            */
/*          II. INDIVIDUAL LEVEL                                              */
/*                                                                            */
/* -------------------------------------------------------------------------- */


use "$data\s02_me_tgo2018.dta", clear
//merge 1:1 grappe menage s01q00a using "$data\s01_me_${iso3}2018.dta", assert(match) nogen
gen numind = s01q00a
merge 1:1 grappe menage numind using "$data\ehcvm_individu_${iso3}2018.dta"
cap noisily assert _m == 3
if _rc {
    tab resid _m
    drop if resid != 1
    tab age if _m == 2
    cap noisily assert age < 3 if _m == 2
    drop if _m == 2 & age < 3
    gen extra_from_ind = _m == 2
    pause
}
drop _m
cap noisily tab resid, sum(resid)
if !_rc {
    keep if resid == 1 // keep only hh members for datasets with that distinction
}
rename numind idi

gen worker = (age >= 15 & age < 65) & inlist(activ12m, 1, 2) // only actually care about this "working age" population
keep if worker
count
pause


/* ---- 1. General ---------------------------------------------------------- */

*** age
label var age "Age in years"
su age 
	
gen agesq = age*age 
label var agesq "Age squared"

*** gender
gen gender = sexe
label define gender 1 "Male" 2 "Female", replace
label value gender gender
label var gender "Gender"
	
ta gender
gen female = (gender == 2)
label var female "female"
	

/* ---- 2. Years of schooling ----------------------------------------------- */

//  a. look at data
tab s02q12 s02q03, m // have q12 for everyone who ever went to school
tab s02q14 if s02q12 == 1, m // have q14 and q16 for those in school 2017/2018
tab s02q29 if s02q12 == 2, m // have q29 and q30 for those who attended school previously

//  b. construct years of education
gen level = s02q14 if s02q12 == 1     // level (primary, secondary etc)
replace level = s02q29 if s02q12 == 2

gen class = s02q16 if s02q12 == 1     // class within level (1, 2 etc)
replace class = s02q31 if s02q12 == 2

recode level (1 2 = 0) (3 4 = 6) (5 6 = 10) (7 8 = 13), gen(base_yrs) // years completed before reaching current level

gen educy = base_yrs + class
replace educy = 0 if level == 1 // no years for preschool
replace educy = 0 if s02q03 == 2 // never went to school

//  c. check
tab educy
tab educy gender, nofreq col
recode age (15/24 = 1 "15-24") (25/34 = 2 "25-34") (35/44 = 3 "35-44") (45/54 = 4 "45-54") (55/64 = 5 "55-64"), gen(age_group)
tab educy age_group, nofreq col
cap noisily assert inrange(educy, 0, 30)
if _rc {
    bys sex age_group milieu: egen mededucy = median(educy)
    replace educy = mededucy if educy == .
    pause
}

recode educy (0 = 0) (nonmiss = 1), gen(anyed)


/* ---- 3. Extra constructions from section 4 ------------------------------- */

// standard EHCVM individual dataset is missing a couple of things for no good reason
// hours worked for those with activ12m = 2 (family work)
// industry/branch for secondary employment

merge 1:1 grappe menage s01q00a using "$data\s04_me_${iso3}2018.dta", /*assert(using match) keep(match)*/ keepusing(s04q52d s04q32 s04q33 s04q34 s04q36 s04q37) // extra questions needed
cap noisily assert inlist(_m, 2, 3)
if _rc {
    tab extra_from_ind _m
    pause
}


//  a. branch for secondary employment
recode s04q52d (11/30=1) (31/65=2) (100/143=3) (151/410=4) (451/457=5) (503/526=6) ///
              (551/560=7) (601/649=8) (801/853=9) (930=10) ///
			  (501/502 527 650/760 900/924 940/990=11) , gen(branch_sec)
lab var branch_sec "Branche activite empl. sec."
lab val branch_sec brl

//  b. hours worked for activ12m == 2
count if volhor == . & activ12m == 1 // should be just a few
assert volhor == . if activ12m == 2 // originally only constructed for those working outside the home, for no good reason

sum s04q32 s04q33 s04q34 s04q36 s04q37 if activ12m==2
egen med_s04q32=median(s04q32), by(csp)
replace s04q32=med_s04q32 if activ12m==2 & s04q32==0 
egen med_s04q37=median(s04q37), by(csp)
replace s04q37=med_s04q37 if activ12m==2 & s04q37==0 
tab s04q33 activ12m, m
gen conge=12*s04q34/360 if s04q33==1
replace conge=0 if s04q33==2
sum conge
gen moistrav=s04q32-conge
replace volhor = moistrav*s04q36*s04q37 if activ12m==2 
count if volhor == . & activ12m == 2


/* ---- 4. Employment characteristics --------------------------------------- */
//global Xs "hoursf female age agesq educy industry_* empstat_* rural region_* wave_1" -- what we actualy need for Mincer

//  a. working or not
tab activ12m, m
gen emp = inlist(activ12m, 1, 2)
keep if emp == 1

//  b. industry (main)
tab branch activ12m, m
recode branch (1 2 = 1 "agriculture") (3 4 5 = 2 "manufacture") (nonmissing = 3 "services"), gen(industrym)
label var industrym "Industry (main)"
cap noisily assert industrym < .
if _rc {
    bys sex milieu region: egen modeind = mode(industrym)
    replace industrym = modeind if industrym >= .
    pause
    assert industrym < .
    drop modeind
}
tab industry, gen(sector_)
rename (sector_*) (=m)

//  c. employment status (main)
tab csp, m
tab csp activ12m, m
recode csp (9 10 = 1 "employer/self-employed") (1/5 = 2 "salaried") (6 7 8 11 = 3 "other dependant"), gen(empstatm)
label var empstat "Employment type (main)"
tab empstat, gen(empstat_)
rename (empstat_*) (=m)

//  d. hours (main)
sum volhor, d
gen hoursm = volhor
replace hoursm = . if hoursm == 0
cap noisily assert hoursm < .
if _rc {
    bys gender empstatm industrym: egen modehourm = mode(hoursm), minmode
    replace hoursm = modehourm if hoursm >= .
    assert hoursm < .
}

//  e. industry (secondary)
tab emploi_sec
// not in the prepared individual dataset, will construct following model for branch
tab branch_sec emploi_sec, m 
recode branch_sec (1 2 = 1 "agriculture") (3 4 5 = 2 "manufacture") (nonmissing = 3 "services"), gen(industrys)
label var industrys "Industry (secondary)"
cap noisily assert industrys < . if emploi_sec
if _rc {
    bys sex milieu region: egen modeind = mode(industrys), minmode
    replace industrys = modeind if industrys >= . & emploi_sec
    pause
    assert industrys < . if emploi_sec
}
tab industrys, gen(sectors_)
rename (sectors_*) (sector_*s)

//  f. employment status (secondary)
tab csp_sec, m
tab csp emploi_sec, m
recode csp_sec (9 10 = 1 "employer/self-employed") (1/5 = 2 "salaried") (6 7 8 11 = 3 "other dependant") (nonm = .), gen(empstats)
label var empstats "Employment type secondary"
assert inrange(empstats, 1, 3) if emploi_sec & empstats < .
cap noisily assert empstats < . if emploi_sec
if _rc {
    bys sex milieu region: egen modeemp = mode(empstats), minmode
    replace empstats = modeemp if empstats >= . & emploi_sec
    pause
    assert empstats < . if emploi_sec
    assert inrange(empstats, 1, 3) if emploi_sec
}
tab empstats, gen(empstats_)
rename (empstats_*) (empstat_*s)

//  g. hours (secondary)
count if volhor_sec >= . & emploi_sec == 1 
sum volhor_sec, d
gen hourss = volhor_sec
replace hourss = . if hourss == 0
cap noisily assert hourss < . if emploi_sec == 1
if _rc {
    bys gender empstats industrys: egen modehours = mode(hourss), minmode
    replace hourss = modehours if hourss >= . & emploi_sec == 1
    cap noisily assert hourss < . if emploi_sec == 1
    if _rc {
        drop modehours
        egen modehours = mode(hourss)
        replace hourss = modehours if hourss >= . & emploi_sec == 1
    }
    pause

}


/* ---- 5. Reshape to job-level --------------------------------------------- */

//  a. reshape
gen double idh = hhid
keep idh idi female age agesq educy hours* sector_* empstat_* emploi_sec csp branch branch_sec
reshape long hours sector_1 sector_2 sector_3 empstat_1 empstat_2 empstat_3, i(idh idi) j(idj) string

//  b. drop secondary job for those with none
drop if emploi_sec == 0 & idj == "s"

//  c. weight jobs
replace hours = 16*365 if hours > 16*365 & hours < .
bys idh idi: egen tothr = sum(hours)
gen jwgt = hours/tothr

drop emploi_sec tothr


/* ---- 6. Checks ----------------------------------------------------------- */

isid idh idi idj
assert inrange(age, 5, 105)
assert agesq == age^2
assert inlist(female, 0, 1)
foreach var of varlist sector_* empstat_* {
    assert inlist(`var', 0, 1)
}
egen scheck = rowtotal(sector_*)
assert scheck == 1
egen echeck = rowtotal(empstat_*)
assert echeck == 1
drop scheck echeck
assert hours > 0 & hours <= 5840
assert jwgt > 0
bys idh idi: egen tot_wgt = sum(jwgt)
assert abs(tot_wgt-1) < 0.00001
drop tot_wgt

drop if inlist(idh, 3806, 16507, 38710, 38807, 38901, 39012, 39509, 40604, 42304, 42310, 42311)

save "$temp\MPO_ind_${iso3}.dta", replace


/* ---- 7. Checks of both datasets together --------------------------------- */

use "$temp\MPO_ind_${iso3}.dta", clear
collapse (mean) age, by(idi idh)
collapse (count) numind = idi, by(idh)
merge 1:1 idh using "$temp\MPO_hh_${iso3}.dta", assert(match using)
*assert nworker == 0 if _m == 2
assert numind == nworker if _m == 3

