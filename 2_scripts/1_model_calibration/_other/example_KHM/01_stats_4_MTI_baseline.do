/*===============================================================================
 Computing MTI stats 
*=======================================================================*/

use "$data_proc/cses_lab_i.dta", clear 
merge 1:1 hhid persid using "$data_proc/cses_proccesed.dta", nogen keepusing(female educ_hl educ_never age ind_agg_main ind_det_main quintile_cons_pc hh_weight employed consum_pc consum_pc_pp totalincomeX_pc hhsize)


/*===============================================================================
 Education - Age - Sector categories 
*=======================================================================*/

// Education 
	recode educ_hl (0/5 88 98 21=1 "Low-skill") (6 7 8 9 13=2 "Middle-skill") (10 11 12 14/20=3 "High-skill") , gen (educ_g)
	replace educ_g=1 if educ_never==2 // q02c04: ever attended school 

/*Alternative recode 
educ_hl (0/6 88 98 21=1) (7/14=2) (15/20=3) , gen (educ_g2)
replace educ_g2=1 if educ_never==2 // q02c04: ever attended school 
*/


// Age
recode age (0/25=1 "<=25 yo" ) (26/35=2 "26-35 yo") (36/55=3 "36-55 yo") (55/110=4 "55+ yo"), gen(age_g)


// sector 
recode  ind_det_main	(1 2 = 1  		"Forestry and Other Agriculture") ///
						(101 = 2 		"Rice") ///
						(102 104 = 3	"Perennial crops, vegetables, melons, roots")  ///
						(3 103 = 4		"Fishery & Livestock")	///
						(4 6 = 5 		"Mining and Utilities") ///
						(5	 = 6		"Manufacturing" ) ///
						(7 	 = 7		"Construction"  ) ///
						(501  =8 		"Manufacture of wearing apparel" ) ///
						(8 801 802 = 9  "Wholesale & Retail") ///
						(9 10 = 10 		"Transp, Commun, Hotel and rest" ) ///
						(11 12 13 14 15 16 = 11 "Bussines, Finance, Goverment and other services" ), gen(sec_g)
						

/*===============================================================================
* Shares on total wage income by skill, gender and broader sector across all households  for each quantile 
*===============================================================================*/

/*============== Compute earnings and employment ==========*/

egen earnings_i=rowtotal(earnings_nonag_i earnings_ag_i)
egen lab_income_i=rowtotal(earnings_nonag_i earnings_ag_i wage_i)

foreach v in wage_i earnings_i lab_income_i {
	gen emp_`v'=1 if `v'!=0
}

keep if employed==1

*Add a duplicate of the dataset to create the economy-wide sectors 
preserve 

	replace sec_g=1000
	tempfile all_sectors_dta
	save `all_sectors_dta'

restore 

append using `all_sectors_dta'

collapse (sum)  wage_i earnings_i lab_income_i emp_wage_i emp_earnings_i emp_lab_income_i [iw=hh_weight], by(educ_g female sec_g quintile_cons_pc)

label define sec_g 1000 "All economy", add
label val sec_g sec_g
	
/*============== Organize variables and compute shares  ==========*/

fillin educ_g female sec_g quintile_cons_pc

foreach v in wage_i earnings_i lab_income_i emp_wage_i emp_earnings_i emp_lab_income_i {
	
	replace `v'=0 if _fillin==1
	
	bysort educ_g female sec_g: egen `v'_tot=total(`v')
	
	gen sh_`v'=`v'/`v'_tot
	replace sh_`v'=0 if _fillin==1 // in case the denominator `v'_tot
	drop `v'_tot
	
	bysort educ_g female sec_g: egen test_`v'=total(sh_`v')
}

/*==============  Cleaning and exporting  ==========*/

// Cleaning 
sum test_*, d
drop test* _fillin

label var wage_i 				"total wage by quintile (000 monthly riels)"
label var earnings_i 			"total earnings by quintile (000 monthly riels) "
label var lab_income_i 			"total lab income (wage+earnings) by quintile (000 monthly riels)"
label var emp_wage_i 			"total salaried work by quintile (numb workers)"
label var emp_earnings_i 		"total earners by quintile (numb workers)"
label var emp_lab_income_i 		"total workers by quintile (numb workers)"
label var sh_wage_i 			"Share wage bill by quintile as percent"
label var sh_earnings_i 		"Share earnings bill  by quintile as percent"
label var sh_lab_income_i 		"Share lab income (wage+earnings) by quintile as percent "
label var sh_emp_wage_i 		"Share salaried workers by quintile as percent"
label var sh_emp_earnings_i 	"Share non-salaried workers by quintile as percent"
label var sh_emp_lab_income_i 	"Share all workers by quintile as percent"

export excel using "$results/data_xls_dta/MTI_stats.xlsx", sheet(wage_emp_dist_bas_reis) sheetreplace first(varlab)


keep educ_g female sec_g quintile_cons_pc sh_*
tempfile stats
save `stats', replace 

// Reshape


///---> labor income share 

tempfile wage_bill
local i=0
foreach v in wage_i earnings_i lab_income_i {
local ++i

	use `stats', clear 
	keep educ_g female sec_g sh_`v' quintile_cons_pc
	
	ren sh_`v' value
	gen income_concept="`v'"
	
	gen indicator="Share of income"
	
	
	if `i'==1 {
		save `wage_bill', replace 
	}
	else {
		append using `wage_bill' 
		save `wage_bill', replace 
	}
	
}


///---> employment 

tempfile employment 
local j=0
foreach v in emp_wage_i emp_earnings_i emp_lab_income_i {
local ++j

	use `stats', clear 
	keep educ_g female sec_g  sh_`v' quintile_cons_pc
	
	local inc = substr("`v'",5,.)
	
	ren sh_`v' value		
	gen income_concept="`inc'"
	gen indicator="Share of employment"
	
	
	if `j'==1 {
		save `employment', replace 
	}
	else {
		append using `employment' 
		save `employment', replace 
	}
		
}

use  `wage_bill', clear 
append using  `employment'

export excel using "$results/data_xls_dta/MTI_stats.xlsx", sheet(wage_emp_dist_baseline) sheetreplace first(var)

/*===============================================================================
* Economy Wide labor income, total income, consumption  
*===============================================================================*/

use `all_sectors_dta', clear 

bysort hhid: egen lab_income_pc=total(lab_income_i/hhsize)

gcollapse (sum)  lab_income_pc  consum_pc totalincomeX_pc consum_pc_pp [iw=hh_weight], by(quintile_cons_pc)

foreach v in lab_income_pc  consum_pc totalincomeX_pc consum_pc_pp {
	
	egen `v'_tot=total(`v')
	gen sh_`v'=`v'/`v'_tot
	drop `v'_tot
}


label var sh_lab_income_pc 		"Share labor inc (earnings+salaries) by quintile"
label var sh_consum_pc 			"Share cons by quintile"
label var sh_totalincomeX_pc 	"Share total inc (lab+transf+pens) by quintile"
label var sh_consum_pc_pp 		"Share cons spatially defl by quintile"

export excel using "$results/data_xls_dta/MTI_stats.xlsx", sheet(income_position) sheetreplace first(varlab)


/*===============================================================================
* Land and Capital 
*===============================================================================*/

///---> Capital and Land 

use "$data_proc_tmp/tmp_labor_income.dta", clear 

keep propertyincomeX quintile_cons_pc hhsize hh_weight

gen propertyincomeX_pc=propertyincomeX/hhsize

collapse (sum) propertyincomeX_pc [iw=hh_weight], by(quintile_cons_pc)

egen tot=total(propertyincomeX_pc)
gen sh_propertyincomeX_pc=propertyincomeX_pc/tot
keep sh_propertyincomeX_pc quintile_cons_pc

label var sh_propertyincomeX_pc "Share property income (land and capital)"
label var quintile_cons_pc "Quintile of per-capita consumption"
format sh_propertyincomeX_pc %4.3f

export excel using "$results/data_xls_dta/MTI_stats.xlsx", sheet(land_capital) sheetreplace first(varlab)

/*===============================================================================
* Goverment transfers 
*===============================================================================*/

use "${data_proc}/tax_transfers_pc.dta", clear 

collapse (sum)  taxes_total_pc transfer_c_total_pc [iw=hh_weight], by(quintile_cons_pc)

foreach j in taxes_total_pc transfer_c_total_pc {
egen tot_`j'=total(`j')
gen sh_`j'=`j'/tot_`j'
}

keep sh_* quintile_cons_pc

label var sh_taxes_total_pc "Shares of dir taxes by quintile (pit, cap, prop, regist)"  
label var sh_transfer_c_total_pc "Shares of direct transfers by quintile"
export excel using "$results/data_xls_dta/MTI_stats.xlsx", sheet(taxes_transfers) sheetreplace first(varlab)



