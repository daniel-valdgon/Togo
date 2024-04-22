/*============================================================================================
Project:   CCDR Togo
Author:    Kolohotia Kadidia Kone/konkadidia19@gmail.com
Creation Date:  October 2023
Output: Transfers
============================================================================================*/

use "$temp\MPO_hh_TGO.dta", clear 
	keep idh ytrg remit_sent remit_received
	preserve
	
	use "$temp/02 Load groups.dta", clear 
	collapse (max) pcexp quanturb quantrural weight, by(idh) 
	tempfile groupuniq
	save `groupuniq'
	restore
	
merge m:1 idh  using `groupuniq' , keep(3) nogen keepus (weight quanturb quantrural pcexp)

//Define excel sheet 
putexcel set "$results/SAMshares.xlsx", sheet(transfers) modify

///Transfers from Government

//Sum of transfert received from gov
gen transf_gov= ytrg

//group by Urban quintils
preserve 
collapse (sum) transf_gov [iw=weight], by(quanturb)
drop if quanturb==.

//write in the excel sheetsheet

tabstat transf_gov, by(quanturb) save
qui tabstatmat A, nototal
putexcel G58 = matrix(A)

restore

//group by Rural quintils
preserve 
collapse (sum) transf_gov [iw=weight], by(quantrural)
drop if quantrural==.

//write in the excel sheetsheet

tabstat transf_gov, by(quantrural) save
qui tabstatmat A, nototal
putexcel G53 = matrix(A)

restore


///Transfers sent and received by household

//Define excel sheet 
putexcel set "$results/SAMshares.xlsx", sheet(transfers_1) modify

///Transfers sent by household

//group by Urban quintils

preserve

collapse (sum) remit_sent [iw=weight], by(quanturb)
drop if quanturb==.

//write in the excel sheetsheet

tabstat remit_sent, by(quanturb) save
qui tabstatmat A, nototal
putexcel A1 = "Transfers sent"
putexcel A2 = "Urban Q1"
putexcel A3 = "Urban Q2"
putexcel A4 = "Urban Q3"
putexcel A5 = "Urban Q4"
putexcel A6 = "Urban Q5"
putexcel B2 = matrix(A)

restore

//group by Rural quintils

preserve

collapse (sum) remit_sent [iw=weight], by(quantrural)
drop if quantrural==.

//write in the excel sheetsheet

tabstat remit_sent, by(quantrural) save
qui tabstatmat A, nototal
putexcel A9 = "Rural Q1"
putexcel A10 = "Rural Q2"
putexcel A11 = "Rural Q3"
putexcel A12 = "Rural Q4"
putexcel A13 = "Rural Q5"
putexcel B9 = matrix(A)

restore

///Transfers received by household

//group by Urban quintils

preserve

collapse (sum) remit_received [iw=weight], by(quanturb)
drop if quanturb==.

//write in the excel sheetsheet

tabstat remit_received, by(quanturb) save
qui tabstatmat A, nototal
putexcel A15 = "Transfers received"
putexcel A16 = "Urban Q1"
putexcel A17 = "Urban Q2"
putexcel A18 = "Urban Q3"
putexcel A19 = "Urban Q4"
putexcel A20 = "Urban Q5"
putexcel B16 = matrix(A)

restore

//group by Rural quintils

preserve

collapse (sum) remit_received [iw=weight], by(quantrural)
drop if quantrural==.

//write in the excel sheetsheet

tabstat remit_received, by(quantrural) save
qui tabstatmat A, nototal
putexcel A22 = "Rural Q1"
putexcel A23 = "Rural Q2"
putexcel A24 = "Rural Q3"
putexcel A25 = "Rural Q4"
putexcel A26 = "Rural Q5"
putexcel B22 = matrix(A)

restore

