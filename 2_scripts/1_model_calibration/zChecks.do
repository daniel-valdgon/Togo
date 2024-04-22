/*============================================================================================
Project:   CCDR Togo
Author:    Kolohotia Kadidia Kone/konkadidia19@gmail.com
Creation Date:  October 2023
Output: Checking
============================================================================================*/



*********************Checking ∑ili+nlh=ch+remitsent ****************************
use "$temp/labor_ind_TGO.dta", clear 
	
	collapse (sum) li salaried_income self_employee_income, by(idh)
	
	tempfile labor_income
	save `labor_income'
	
	
use "$temp/MPO_hh_TGO.dta", clear
	collapse (sum) nonlabor_income consumption noncons_exp remit_sent remit_received ytrg ynl, by(idh)
	merge 1:1 idh using `labor_income'
	replace li=0 if li==.
	keep if _m==3
	drop _m
	
	egen li_nli=rowtotal(li nonlabor_income)
	egen cons_remitsent=rowtotal(consumption remit_sent) 
	
	assert li_nli==cons_remitsent, rc0 null  // negativ li income which replace by 0 
	

*********************Checking li=wi+selfi ****************************
	

	replace li= round(li,1)
	replace salaried_income= round(salaried_income,1)
	replace self_employee_income= round(self_employee_income,1)
	
	replace salaried_income=0 if salaried_income==.
	replace self_employee_income=0 if self_employee_income==.
	
egen tot_i=rowtotal(salaried_income self_employee_income)


assert li==tot_i //different by a single digit

gen test= tot_i/li if li!=0
summarize test, detail

*********************nlh=gh+oh****************************	

egen tot_nl=rowtotal(ytrg ynl remit_received)
assert nonlabor_income==tot_nl //**ytrg is transfers from gov **ynl is other nli 
