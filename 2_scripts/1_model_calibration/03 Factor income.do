/*============================================================================================
Project:   CCDR Togo
Author:    Kolohotia Kadidia Kone
Creation Date:  October 2023
Output: 
============================================================================================*/

use "$temp/labor_ind_TGO.dta", clear
merge 1:1 idh idi using "$temp/02 Load groups.dta", keep(3) nogen keepus(genderXskill skilled industry small_industry weight quanturbli quantruralli quantruralwage quanturbwage)

*************Compute mixed income and capital land *********************
gen wage=salaried_income

///Mixed income traitment
gen ebe_factor=1.6
gen mixed_income=self_employee_income* ebe_factor //Define mixed income

gen self_factor=self_employee_income/mixed_income //Define part of self employed income in mixed income
egen total_lab=rowtotal(wage mixed_income)

///Capital land 
gen capital_land=mixed_income* (1-self_factor) //Define capital land 

gen capital_factor=0.4

gen capital_income=capital_factor*capital_land
gen land_income=capital_land*(1-capital_factor)

egen tot_capital_land=rowtotal(capital_income land_income)
************************Factor payement********************

//Define excel sheet 
putexcel set "${toolA}\SAMshares.xlsx", sheet(factor payments) modify


///**** factor payment EBE+share of EBE*********

///by skills

preserve 

collapse (sum) total_lab [iw=weight], by(skilled small_industry)
reshape wide total_lab , i(skilled) j(small_industry)

//write in the excel sheetsheet

tabstat total_lab*, by(skilled) save
qui tabstatmat A, nototal
putexcel C19 = matrix(A)

restore


/// by genderXskill
preserve 

collapse (sum) total_lab [iw=weight], by(genderXskill small_industry)
reshape wide total_lab , i(genderXskill) j(small_industry)

//write in the excel sheetsheet

tabstat total_lab*, by(genderXskill) save
qui tabstatmat A, nototal
putexcel C32 = matrix(A)

restore

///**** factor payment capital (rest of EBE)

///Complete
preserve 

collapse (sum) capital_income land_income [iw=weight], by(small_industry)

//write in the excel sheetsheet

tabstat capital_income land_income , by(small_industry) save
qui tabstatmat A, nototal
putexcel C26 = matrix(A')

restore


/// by genderXskill

***********************Factor income***********************

//Define excel sheet 
putexcel set "${toolA}\SAMshares.xlsx", sheet(factor inc) modify


///**** Rural quant*********

//Generate factor income by quantruralwage and Skills

preserve 

collapse (sum) wage [iw=weight], by(skilled quantruralwage)
reshape wide wage , i(quantruralwage) j(skilled)
drop if quantruralwage==.

//write in the excel sheetsheet

tabstat wage1 wage2 wage3, by(quantruralwage) save
qui tabstatmat A, nototal
putexcel C6 = matrix(A)

restore

//Generate factor income by quantruralwage and GenderXskills

preserve 

collapse (sum) wage [iw=weight], by(genderXskill quantruralwage)
reshape wide wage , i(quantruralwage) j(genderXskill)
drop if quantruralwage==.

//write in the excel sheetsheet

tabstat wage*, by(quantruralwage) save
qui tabstatmat A, nototal
putexcel J6 = matrix(A)

restore


///**** Urban**********

//Generate factor income by quanturbwage and skills

preserve 

collapse (sum) wage [iw=weight], by(skilled quanturbwage)
reshape wide wage , i(quanturbwage) j(skilled)
drop if quanturbwage==.

//write in the excel sheetsheet

tabstat wage1 wage2 wage3, by(quanturbwage) save
qui tabstatmat A, nototal
putexcel C11 = matrix(A)

restore

//Generate factor income by quanturbwage and GenderXskills

preserve 

collapse (sum) wage [iw=weight], by(genderXskill quanturbwage)
reshape wide wage , i(quanturbwage) j(genderXskill)
drop if quanturbwage==.

//write in the excel sheetsheet

tabstat wage*, by(quanturbwage) save
qui tabstatmat A, nototal
putexcel J11 = matrix(A)

restore