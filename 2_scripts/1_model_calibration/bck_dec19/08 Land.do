/*============================================================================================
Project:   		CCDR Togo
Author:    		Kolohotia Kadidia Kone
Creation Date:  Decembre 2023
Output: 		Land
============================================================================================*/

**Compute base for this work
use "$data\s16a_me_tgo2018.dta",clear 
	ren s16aq02 s16cq02
	ren s16a01a s16cq01
	ren s16aq03 s16cq03
	
merge 1:m vague grappe menage s16cq02 s16cq03 s16cq01 using	"$data\s16c_me_tgo2018.dta"


*******meters of land for household

//Area of land
	
tab s16aq09b 
clonevar plot_area_unity=s16aq09b 

tab s16aq09a
clonevar area_plot_sm =s16aq09a

//Total area land in square meters
	replace area_plot_sm= 10000*area_plot_sm if plot_area_unity==1
	
	
	*Land owners
	preserve
	
	tab s16aq10 
	clonevar landowner=s16aq10  
	keep if landowner==1 // we keep only those who are landowner
	
	gen type="landowner" 
	
	keep area_plot_sm grappe menage type
	
	collapse (sum) area_plot_sm, by(grappe menage type)
	
	tempfile plot_area_lo
	save `plot_area_lo'
	
	restore
	
	*Non land owners
	
	preserve
	
	tab s16aq10 
	clonevar nlandowner=s16aq10  
	keep if nlandowner!=1 // we keep only those who are non landowner
	
	gen type="nlandowner" 
	
	keep area_plot_sm grappe menage type
	collapse (sum) area_plot_sm , by(grappe menage type)
	
	append using `plot_area_lo'
	
	tempfile plot_area
	save `plot_area'
	
	restore
	
	preserve
	
	use "$temp/02 Load groups.dta", clear 
	
	keep menage grappe quanturb quantrural weight
	collapse  quanturb quantrural weight , by(grappe menage)
	
	merge 1:m grappe menage using `plot_area'
	ta _m
	keep if _m==3
	drop _m
	
	tempfile plot_area_by
	save `plot_area_by'
	
	restore
	
	*****
	
	use `plot_area_by', clear
	
	
	//Define dir
	putexcel set "$results/SAMshares.xlsx", sheet(land) modify

	
	****************LandO
	
*****For urbans	
	
	preserve
	
	collapse (sum) area_plot_sm [iw=weight] if type=="landowner", by(quanturb)
	drop if quanturb==.

//write in the excel sheetsheet

	tabstat area_plot_sm, by(quanturb) save
	qui tabstatmat A, nototal
	putexcel B3 = matrix(A)

	restore
	
*****For rural
	
	preserve
	
	collapse (sum) area_plot_sm [iw=weight] if type=="landowner", by(quantrural)
	drop if quantrural==.

//write in the excel sheetsheet

	tabstat area_plot_sm, by(quantrural) save
	qui tabstatmat A, nototal
	putexcel B8 = matrix(A)

	restore
	
	***************Non landO
	
*****For urbans	
	
	preserve
	
	collapse (sum) area_plot_sm [iw=weight] if type=="nlandowner", by(quanturb)
	drop if quanturb==.

//write in the excel sheetsheet

	tabstat area_plot_sm, by(quanturb) save
	qui tabstatmat A, nototal
	putexcel E3 = matrix(A)

	restore
	
*****For rural
	
	preserve
	
	collapse (sum) area_plot_sm [iw=weight] if type=="nlandowner", by(quantrural)
	drop if quantrural==.

//write in the excel sheetsheet

	tabstat area_plot_sm, by(quantrural) save
	qui tabstatmat A, nototal
	putexcel E8 = matrix(A)

	restore
	
	
