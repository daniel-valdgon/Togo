/*============================================================================================
Project:   CCDR Cambodia
Author:    Daniel Valderrama
Creation Date:  March 10th
Output: Preparing data to be used by the ms_reweight 
============================================================================================*/


use "$data_proc/cses_lab_i.dta", clear 
	merge 1:1 hhid persid using "$data_proc/cses_proccesed.dta", nogen keepusing(female educ_hl educ_never age ind_agg_main ind_det_main quintile_cons_pc hh_weight employed consum_pc consum_pc_pp totalincomeX_pc hhsize urban povertyline psu quintile_cons_pc_pp bottom40 poor) 

// Adding geographic variables 
destring psu,replace
merge m:1 psu using "$data_raw/CSES_2019/CSES_2019/VCSES2019/Area_information.dta", nogen keepusing(province_name province_code district_name  commune_name village_name ) // 1_KHM/pre-analysis/raw/CSES 2019/CSES2019/VCSES2019

// Year of the survey 
merge m:1 hhid using "$data_raw/CSES_2019/CSES_2019/2019hh_s99_singlequestions.dta", nogen keepusing(year month)     //1_KHM/pre-analysis/raw/CSES 2019/CSES2019/
ren year svy_year
ren month svy_month

// Status of employment
merge 1:1 hhid persid using "$data_raw/CSES_2019/CSES_2019/2019hh_s15_labor7days.dta", nogen keepusing(q15_c26 q15_c31 q15_c28 q15_c23) // also q15_c27a q15_c28 q15_c30 q15_c32  q15_c28 q15_c30 


// Renaming variables that we will not change their value labels 
rename hh_weight weight
rename hhsize hsize
destring hhid, replace
clonevar  idh= hhid
clonevar idp=persid

label variable age "Age of individual (continuous)"
label variable hhid "Household identifier"
label variable hsize "Household size"
label variable weight "Weight"
*label variable labor_income "Individual wage income"


*-------- gender --------
// Male and gender variable. Although ms_reweight only needs gender
	assert female!=.
	//--->Male 
	recode female (0 = 1 "Male") (1=0 "Female") (nonmissing=.), gen(male)
	label variable male "==1 if male"
	/* gen male=.
	replace male=1 if female==0  // V 
	replace male=0 if female==1
	label define male 1 male 0 female
	label values male male
	*/
	//---> Gender
	recode female (0 = 1 "Male") (1=2 "Female") (nonmissing=.), gen(gender)
	label variable gender "RECODE of female =1 if male =2 if female"
	drop female 

*-------- education and skills --------
// Generating calif variable from education categories
	recode educ_hl (0/5 88 98 21=1 "Primary or less") (6 7 8 9 13=2 "Middle-high school") (10 11 12 14/20=3 "High school and more") , gen (calif)
	replace calif=1 if educ_never==2 // q02c04: ever attended school 
	replace calif=1 if age<=3 //  Before was missing and deleting observations
	
// Creating skilled variable. 1 for 10+ years of education.
gen gend_skilled=. 
local i=0
foreach g in 1 2 {
	foreach e in 1 2 3 {
	local ++i
		replace  gend_skilled=`i'	 if 	gender==`g' & calif==`e' & ind_det_main!=.
	}
}
gen skilled=calif 

*-------- industry --------
//industry (11 sectors of MTI stats)
//keep if industry==1 | industry==2 | industry==3 | industry==4 | industry==5 | industry==6 | industry==7 | industry==8

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
						(11 12 13 14 15 16 = 11 "Bussines, Finance, Goverment and other services" ), gen(industry)


recode  ind_det_main	(1 2 101 102 104 3 103 = 1  "Agriculture") ///
						(4 6 5 7 501= 2		"Manufacturing" ) ///
						(8 801 802 9 10= 3  "Retail, Transport, Commun, HOtel and rest") ///
						(11 12 13 14 15 16 = 4 "Bussines, Finance, Goverment and other services" ), gen(small_industry)




*------- Spatial 
recode urban (0=1 "rural") (1=2 "urban") (nonmissing=.), gen(urb)
drop urban

*-------- Labor income 
// Labor income: tales the variable salaryX_i. It does not include income coming from agricultural activities
egen lab_income_i=rowtotal(earnings_nonag_i earnings_ag_i wage_i)

label var earnings_nonag_i 		"Non-ag earnings (000 monthly riels)"
label var wage_i 					"wage (000 monthly riels)"
label var earnings_ag_i 			"Ag earnings (000 monthly riels)"
label var lab_income_i 			"Wages + earnings (000 monthly riels)"


*-------- Imputing labor income 

*Labor income imputation 
preserve 
	encode province_name, gen (prov)
	gen lab_income_i_imp=lab_income_i if lab_income_i!=0
	keep lab_income_i_imp ind_det_main urb gend_skilled employed weight   prov  hsize totalincomeX_pc educ_hl hhid  persid
	keep if employed==1
	replace lab_income_i_imp=. if lab_income_i_imp==0 // should not be needed
	mi set wide 
	mi register regular ind_det_main urb gend_skilled employed weight prov  hsize totalincomeX_pc
	mi register imputed lab_income_i
	mi set M = 1
	mi impute pmm lab_income_i_imp i.ind_det_main i.urb i.gend_skilled i.prov if employed==1 [aw=weight] ,  add(1) knn(5) rseed(8029) replace noisily // bootstrap is not allowed in combination with weights 
	replace lab_income_i_imp=_1_lab_income_i_imp 
	mi unset 

	keep hhid persid lab_income_i_imp
	tempfile impute_values
	save `impute_values', replace 
restore 

merge 1:1 hhid persid using `impute_values', assert(master matched) keep(master matched) keepusing (lab_income_i_imp) nogen


*-------- Percapita income components 
//labor 
bys idh: egen  lab_pc=total(lab_income_i/hsize) /* Aggregate to labor per-capita income */
label var lab_pc   	"Labor income pc (observed in hh survey)"

bys idh: egen lab_pc_imp=total(lab_income_i_imp/hsize) /* Aggregate to labor per-capita income */
label var lab_pc_imp "Labor income pc after pmm imputation (observed in hh survey)"
	
//Only one version of non lab inc
gen non_lab_pc=round(totalincomeX_pc-lab_pc) /* Adding back "non-labor" income */
label var non_lab_pc        "Non labor income pc (observed in hh survey)"
	
//Total 
egen totalincomeX_pc_imp=rowtotal(lab_pc_imp non_lab_pc)
label var totalincomeX_pc_imp    "Total income lab_pc_impute + non_lab_pc obs (observed in hh survey)"

*-------- Household characteristics -------

// Finding main income earners (random workers for workers with zero income or same income) 
set seed 89743
gen r=runiform()
egen a_lab_income_i=rowtotal(lab_income_i r)
bysort hhid: egen _mi_earn=max(a_lab_income_i) 

gen mi_earner= _mi_earn==a_lab_income_i
replace mi_earner=0 if lab_income_i==0
drop _mi_earn a_lab_income_i r
	//test 
	// bysort hhid: egen test=total(mi_earner)

gen _mainearner_sex=gender if mi_earner==1
gen _mainearner_skill=calif  if mi_earner==1
gen _mainearner_gendskill=gend_skilled if mi_earner==1

foreach v in mainearner_sex mainearner_skill mainearner_gendskill {
	bysort hhid: egen `v'=max(_`v')
	replace `v'=999 if `v'==.
	drop _`v'
}


label define gend_skilled 1 "Male-lowsk" 2 "Male-midsk" 3 "Male-highsk" 4 "Fem-lowsk" 5 "Fem-midsk" 6 "Fem-highsk" 

label value mainearner_sex gender 
label value mainearner_skill calif 
label value  mainearner_gendskill gend_skilled
label value  gend_skilled gend_skilled

label var mainearner_sex "main earner sex"
label var mainearner_skill "main earner skill"
label var mainearner_gendskill "main earner skill"


clonevar urban=urb

foreach v in mainearner_sex mainearner_skill mainearner_gendskill urb {
decode `v', gen (lb_`v')
replace lb_`v'="99" if lb_`v'==""
drop `v'
ren lb_`v' `v' 
}
 

gen sep=""
label var sep "*********demographics*********"

gen sep1=""
label var sep1 "****** spatial ***********"

gen sep11=""
label var sep11 "****** employment characteristics  ***********"

gen sep2=""
label var sep2 "****** indiv earnings ***********"

gen sep3=""
label var sep3 "****** household pc income sources ***********"

gen sep4=""
label var sep4 "****** Main earner characteristics ***********"

gen sep5=""
label var sep5 "****** welfare ***********"

order hhid persid psu idh idp weight svy_year svy_month ///
		sep male gender calif gend_skilled skilled hsize educ_never educ_hl age  ///
		sep1 province_code province_name district_name commune_name village_name urban urb ///
		sep11 ind_agg_main employed ind_det_main q15_c23 q15_c26 q15_c28 q15_c31 industry small_industry ///
		sep2 wage_i earnings_ag_i earnings_nonag_i  lab_income_i lab_income_i_imp ///
		sep4 mi_earner mainearner_sex mainearner_skill mainearner_gendskill ///
		sep3 lab_pc lab_pc_imp non_lab_pc totalincomeX_pc_imp totalincomeX_pc ///
		sep5 povertyline bottom40 quintile_cons_pc_pp consum_pc_pp consum_pc





save "$data_proc/cses2reweight.dta", replace

/*Method to expand household survey observations such that final weights after reweigthing have lower proportion of zeros
still the pro of ceros increased and produce contraintuitive stats between 2020 and 2030
	gen  expand=weight/10
	expand expand
	ren weight old_weight
	gen weight=10
*/


save "$data/hh_survey/KHM2019.dta", replace

exit 

