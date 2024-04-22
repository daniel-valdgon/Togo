/*============================================================================================
Project:   		CCDR Togo
Author:    		Kolohotia Kadidia Kone
Creation Date:  Decembre 2023
Output: 		Capital
============================================================================================*/

**Assert of non agro firms
use "$data\s10_2_me_tgo2018",clear 

	**Variables to use 
	//Keep value of all asert that firms possess
	
	clonevar local_v=s10q25 				//value of local 
	clonevar machine_v=s10q36				//value of machines
	clonevar rolling_stocks_v = s10q38		//value of rolling stocks
	clonevar office_furniture_v = s10q40	// value of office fourniture
	clonevar oth_equipment_v=s10q42			// value of other equipments	
	
	****Total capital for firms
	
	egen capital_fna=rowtotal(local_v machine_v rolling_stocks_v office_furniture_v oth_equipment_v)
	
	gen firms_fna =1 if local_v!=.|machine_v!=.|rolling_stocks_v!=.|office_furniture_v!=.|oth_equipment_v!=.
	
	gen type="non agro"
	
	collapse (sum) capital_fna firms_fna, by(grappe menage type)
	
	tempfile fna
	save `fna'

	
**Assert of agro firms	

use "$data\s19_me_tgo2018.dta",clear 

	**compute capital
	
	keep if s19q03==1 //keep only households whose possess equipments
	
	clonevar number_equip= s19q04 
	clonevar sell_price = s19q07
	
	gen capital_fa =number_equip*sell_price
	
	gen firms_fa =1 if capital_fa!=.
	gen type="agro"
	
	collapse (sum) capital_fa firms_fa, by(grappe menage type)
	
	append using `fna'
	
	tempfile capi
	save `capi'
	
	preserve
	
	use "$temp/02 Load groups.dta", clear 
	
	keep menage grappe quanturb quantrural weight
	collapse  quanturb quantrural weight , by(grappe menage)
	
	merge 1:m grappe menage using `capi'
	ta _m
	keep if _m==3
	drop _m
	
	tempfile capital
	save `capital'
	
	restore
	
	*****
	
	use `capital', clear
	
	//Before exporting

	gen Quintiles= "a"
	
	*
	replace Quintiles="Urban Q1" if quanturb==1
	replace Quintiles="Urban Q2" if quanturb==2
	replace Quintiles="Urban Q3" if quanturb==3
	replace Quintiles="Urban Q4" if quanturb==4
	replace Quintiles="Urban Q5" if quanturb==5
	
	*
	replace Quintiles="Rural Q1" if quantrural==1
	replace Quintiles="Rural Q2" if quantrural==2
	replace Quintiles="Rural Q3" if quantrural==3
	replace Quintiles="Rural Q4" if quantrural==4
	replace Quintiles="Rural Q5" if quantrural==5
	
	*
	drop quantrural quanturb
	
	preserve
	
	collapse (sum) capital_fna firms_fna capital_fa firms_fa [iw=weight], by(Quintiles)
	
//write in the excel sheetsheet

	export excel "$results/SAMshares.xlsx", sheetreplace firstrow(variables) sheet("Capital")


	restore	
	
