/*============================================================================================
Project:   CCDR Togo
Author:    Kolohotia Kadidia Kone
Creation Date:  October 2023
Output: Factor income 
============================================================================================*/

use "$temp/labor_ind_TGO.dta", clear
merge 1:1 idh idi using "$temp/02 Load groups.dta", keep(3) nogen keepus(genderXskill skilled industry ind_original weight quanturb quantrural ) 

/* Define returns to labor (wages, EBE, Capital and land)*/

gen wage=salaried_income

gen ebe_factor=0.85
gen mixed_income=self_employee_income* ebe_factor // Labor returns for mixed income 

egen total_lab=rowtotal(wage mixed_income) // all labor returns 

///Capital land 
gen capital_factor=0.4
gen capital_land=self_employee_income* (1-ebe_factor) //Define capital land 
gen capital_income=capital_factor*capital_land
gen land_income=capital_land*(1-capital_factor)
drop capital_land capital_factor ebe_factor

**************************************
/* Export to Factor payments  */
**************************************

putexcel set "$results/SAMshares.xlsx", sheet(factor payments) modify //Define excel sheet 


// Adding names to the sheet of the SAMshares
preserve 
	duplicates drop industry, force 
	sort industry
	keep industry 
	tostring industry, replace 
	decode industry, gen (ss)
	drop industry 
	
	sxpose , clear 
	export excel using "$results/SAMshares.xlsx", sheet("factor payments", modify) cell(C12) 
restore 

// Adding names to the sheet of the SAMshares
 
	
	collapse (sum) wage self_employee_income, by(industry)
	sort industry
	
	tabstat wage self_employee_income, by(industry) save
	qui tabstatmat A, nototal
	putexcel C13 = matrix(A)

	
	export excel using "$results/SAMshares.xlsx", sheet("factor payments", modify) cell(C12) 


// All factor payments

preserve 
	collapse (sum) total_lab [iw=weight], by(skilled industry)
	reshape wide total_lab , i(skilled) j(industry)

	tabstat total_lab*, by(skilled) save
	qui tabstatmat A, nototal
	putexcel C19 = matrix(A)

restore


//Skills and industries
preserve 
	collapse (sum) total_lab [iw=weight], by(skilled industry)
	reshape wide total_lab , i(skilled) j(industry)

	tabstat total_lab*, by(skilled) save
	qui tabstatmat A, nototal
	putexcel C19 = matrix(A)

restore

// gender X skill and industries

preserve 
	
	collapse (sum) total_lab [iw=weight], by(genderXskill industry)
	reshape wide total_lab , i(genderXskill) j(industry)
	
	//write in the excel sheetsheet
	
	tabstat total_lab*, by(genderXskill) save
	qui tabstatmat A, nototal
	putexcel C32 = matrix(A)
	
restore

**************************************
/* Export to Factor income by quintile  */
**************************************
putexcel set "$results/SAMshares.xlsx", sheet(factor inc) modify


// Rural quintiles X skill

preserve 

	collapse (sum) total_lab [iw=weight], by(skilled quantrural)
	reshape wide total_lab , i(quantrural) j(skilled)
	drop if quantrural==.
	
	tabstat total_lab1 total_lab2 total_lab3, by(quantrural) save
	qui tabstatmat A, nototal
	putexcel C6 = matrix(A)

restore

// Rural quintiles X skill-gender

preserve 

	collapse (sum) total_lab [iw=weight], by(genderXskill quantrural)
	reshape wide total_lab , i(quantrural) j(genderXskill)
	drop if quantrural==.
	
	tabstat total_lab*, by(quantrural) save
	qui tabstatmat A, nototal
	putexcel J6 = matrix(A)

restore

// Urban quintiles X skill

preserve 

	collapse (sum) total_lab [iw=weight], by(skilled quanturb)
	reshape wide total_lab , i(quanturb) j(skilled)
	drop if quanturb==.
	
	tabstat total_lab1 total_lab2 total_lab3, by(quanturb) save
	qui tabstatmat A, nototal
	putexcel C11 = matrix(A)

restore

// Urban quintiles X skill-Gender

preserve 

	collapse (sum) total_lab [iw=weight], by(genderXskill quanturb)
	reshape wide total_lab , i(quanturb) j(genderXskill)
	drop if quanturb==.
	
	tabstat total_lab*, by(quanturb) save
	qui tabstatmat A, nototal
	putexcel J11 = matrix(A)

restore


**************************************
/* Export to IO matrix   */
**************************************

