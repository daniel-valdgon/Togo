/*============================================================================================
Project:   CCDR Togo
Author:    Kolohotia Kadidia Kone/konkadidia19@gmail.com
Creation Date:  October 2023
Output: Checking
============================================================================================*/


/* Preparing auxiliary variables */ 

// Number of workers to validate household withouth labor income 

use "${data}\ehcvm_individu_tgo2018.dta", clear

	cap noisily tab resid, sum(resid)
	if !_rc {
		keep if resid == 1 // keep only hh members for datasets with that distinction
	}
	gen worker = (age >= 15 & age < 65) & inlist(activ12m, 1, 2)
	collapse (sum) nworker = worker, by(hhid)
	tab nworker, m
	rename hhid idh
	label var nworker "hh. n worker, resident, 15-65 yo,  Trav-fam or Occupe"
tempfile nworker
save `nworker'

// Income components 
use "${temp}\MPO_hh_${iso3}.dta", clear
	gen hhli = consumption + noncons_exp - nonlabor_income
	keep hhli idh

tempfile income_agg
save `income_agg', replace 

// Adjusted labor income 
use "$temp/labor_ind_TGO.dta", clear 
	
		isid idh idi 
		keep idh li li_MPO salaried_income self_employee_income
		collapse (sum) li_MPO li salaried_income self_employee_income, by(idh)
		
		label var li                   "hh. lab inc"
		label var salaried_income      "hh. lab inc salaried"
		label var self_employee_income "hh. self-employed and employers salaried"
		
tempfile labor_income
save `labor_income'

	
//Main dataset 
use idh  consumption pcc ipcc nonlabor_income noncons_exp remit_sent remit_received ytrg ynl hhsize zref using "$temp/MPO_hh_TGO.dta", 
	
	// k=adjusted labor income 
		merge 1:1 idh using `labor_income', assert(matched master) gen(flag_miss_lab)
	
	// cleaning data 
		foreach v in  li salaried_income self_employee_income {
			replace `v'=0 if `v'==.
		}

	// adding household labor income to check
		merge 1:1 idh using `income_agg', assert(matched master) nogen
		merge 1:1 idh using `nworker'	, assert(matched master) nogen 
		
		bysort idh: egen temp_hhli=total(li)
		cap assert hhli==temp_hhli if nworker!=0 // about 500 observations report low non labor income but have no person working. Therefore we do not have information for the sector of their main occupation. Other 29 observations because negative household labor income 
		drop temp_hhli 
		
/* Defining main variables  */ 
		
// Defining consumption 	
	gen consumption_pc=consumption/hhsize
	gen def=consumption/consumption_pc
	
	label var consumption 		"hh consumption non spat or temp adjusted"
	label var consumption_pc	"Per capita consumption (non deflated)"
	label var def 				"Implicit cons deflators for national poverty"

// Non labor income 
	egen _test_nl=rowtotal(remit_received ytrg ynl)
	assert nonlabor_income== _test_nl
	label var nonlabor_income "hh non-lab inc =remit_received + ytrg + ynl"
	drop _test

// Government transfers is defined as ytrg gov transfers , income from government includes 
	label var ytrg "hh. Government transfers" 
	//	s05q02: retirement pension (civil and military, including veterans) 
	//	s05q04: widow's pension (for loss of spouse) or orphan's pension (for loss of parent)
	//	s05q06:  disability pension (in the event of an accident at work)  
	//	s05q08: alimony (in the event of divorce or separation)


//Other non-labor income variable is defined as ynl
label var ynl "Other non labor income"

	// 	S05q10: Annual income from rental of residential property
	//  	S05q12: Annual amount of income from movable and income (share dividends, interest on investments, etc.)
	//		S05q14: Annual amount of other income (lottery winnings inheritance, sale of goods, etc.)

	label var remit_received "hh. annual remittancess receieved "
	label var remit_sent "hh. annual remittancess sent"

	foreach y in  li ynl remit_received remit_sent nonlabor_income ytrg noncons_exp  hhli {
				gen `y'_pc=`y'/hhsize
	}
	
	/* Residual non labor income */
	gen res_non_labor_pc=hhli_pc*(nworker==0) // when consumption- non labor >0 & nworker==0 
		
	egen income=rowtotal (li_pc nonlabor_income_pc res_non_labor_pc)
	replace income=round(income)
	
	egen cons_remitsent=rowtotal(consumption_pc noncons_exp_pc )  // currently remit_sent_pc==noncons_exp_pc
	replace cons_remitsent=round(cons_remitsent)
	
	gen ratio=cons_remitsent/income
	cap assert cons_remitsent==income , rc0 null // The 34 observations are mostly due to labor income being higher than consumption. The we need to either reduce non labor income or create a negative non labor income residual

	
/*-------------------------------------*/
	* Adding individual level data
/*-------------------------------------*/	

	replace li= round(li,1)
	replace salaried_income= round(salaried_income,1)
	replace self_employee_income= round(self_employee_income,1)
	
	replace salaried_income=0 if salaried_income==.
	replace self_employee_income=0 if self_employee_income==.
	
egen tot_i=rowtotal(salaried_income self_employee_income)

gen ratio_temp=li/tot_i
assert li==tot_i //different by a single digit
drop ratio_temp
