/*============================================================================================
Project:   CCDR Togo
Author:    Kolohotia Kadidia Kone/konkadidia19@gmail.com
Creation Date:  October 2023
Output: Transfers
============================================================================================*/

use "$data/s05_me_tgo2018.dta", clear
	gen hhid = 100*grappe + menage
	ren hhid idh
	preserve
	
	use "$temp/02 Load groups.dta", clear 
	collapse (max) pcexp quanturb quantrural weight, by(idh) 
	tempfile groupuniq
	save `groupuniq'
	restore
	
merge m:1 idh  using `groupuniq' , keep(3) nogen keepus (weight quanturb quantrural pcexp)

//Define excel sheet 
putexcel set result, sheet(transfers) modify

///Transfers from Government

//Sum of transfert received from gov
egen transf_gov= rowtotal(s05q02 s05q04 s05q06 s05q08)

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