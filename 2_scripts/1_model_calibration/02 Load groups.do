/*============================================================================================
Project:   		CCDR Togo
Author:    		Kolohotia Kadidia Kone
Creation Date:  October 2023
Output: 		Preparing groups
============================================================================================*/


****************************Pre traitment*******************************
use "$data/ehcvm_individu_tgo2018.dta", clear
	ren numind idi
	ren hhid idh
	merge 1:1 idh idi using "$temp/labor_ind_TGO.dta", keepusing(li salaried_income self_employee_income)
	gen employee=1 if _m==3
	drop _m
	merge m:1 idh using "$temp/MPO_hh_TGO.dta",nogen keepusing(wgt hhsize) //
	
	gen educ_never=1 if educ_hi==1
	replace educ_never=0 if educ_never==.
	gen hhid=idh

drop zae lien mstat religion nation mal30j aff30j agemar arrmal durarr con30j hos12m couvmal moustiq handit handig alfab scol educ_scol telpor internet activ7j activ12m sectins volhor salaire emploi_sec sectins_sec csp_sec volhor_sec salaire_sec bank serviceconsult persconsult educ_hi
	

// gender 
gen female = (sexe == 2)
	
	
// Renaming variables that we will not change their value labels 
rename wgt weight
rename hhsize hsize
clonevar idp=idi
ren li labor_income
ren diplome educ_hl
ren branch ind_det_main

label variable age "Age of individual (continuous)"
label variable hhid "Household identifier"
label variable hsize "Household size"
label variable weight "Weight"
label variable labor_income "Individual wage income"
label variable educ_hl "high level school"

*************************Gender***********************
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
	drop female male

*********************education and skills*******************************

// Generating calif variable from education categories
	recode educ_hl (0 1=1 "Primary or less") (2 3 4 5 =2 "Middle-high school") (6/10 =3 "High school and more") , gen (calif)
	replace calif=1 if age<=3 //  Before was missing and deleting observations
	
// Creating skilled variable. 1 for 10+ years of education.
gen gend_skilled=. 

local i=0
foreach g in 1 2 {
	foreach e in 1 2 3 {
	local ++i
		replace  gend_skilled=`i' if gender==`g' & calif==`e' & ind_det_main!=.
	}
}

recode gend_skilled (1=1 "Male-lowsk") (2 =2 "Male-midsk") (3=3 "Male-highsk") (4=4 "Fem-lowsk") (5 =5 "Fem-midsk") (6=6 "Fem-highsk") , gen (genderXskill)

gen skilled=calif

label define gend_skilled 1 "Male-lowsk" 2 "Male-midsk" 3 "Male-highsk" 4 "Fem-lowsk" 5 "Fem-midsk" 6 "Fem-highsk" 

*******************************industry*********************************
recode  ind_det_main	(1 = 1  		"Forestry and Other Agriculture") ///
						(2 = 2			"Fishery & Livestock")	///
						(3 4= 3 		"Mining and Utilities") ///
						(5	 = 4		"Manufacturing" ) ///
						(7 	 = 5		"Construction"  ) ///
						(7 8 = 6 		"Transp, Commun, Hotel and rest" ) ///
						(9 10 7 = 11 	"Bussines, Finance, Goverment and other services" ), gen(industry)
						

						recode  ind_det_main	(1 2   = 1  "Agriculture") ///
						(3 4 5 = 2	"Manufacturing" ) ///
						(6 7 8 = 3  "Retail, Transport, Commun, HOtel and rest") ///
						(9 10 11 = 4 "Bussines, Finance, Goverment and other services" ), gen(small_industry)
						

********************************Spatial****************************** 
recode milieu (0=1 "rural") (1=2 "urban") (nonmissing=.), gen(urb)
drop milieu

xtile quanturbli= labor_income[aw=weight] if urb!=. ,nq(5) 
xtile quantruralli= labor_income[aw=weight] if urb==. ,nq(5) 

xtile quanturbwage= salaried_income[aw=weight] if urb!=. ,nq(5) 
xtile quantruralwage= salaried_income[aw=weight] if urb==. ,nq(5) 

************************************************************************

label var employee "Have a job" 
label var educ_never "Never go to school"
label var gend_skilled "GenreXskills"
label var skilled "Skills"

save "$temp/02 Load groups.dta", replace