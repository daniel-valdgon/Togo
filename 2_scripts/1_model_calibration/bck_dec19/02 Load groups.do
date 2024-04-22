/*============================================================================================
Project:   		CCDR Togo
Author:    		Kolohotia Kadidia Kone
Creation Date:  October 2023
Output: 		Preparing groups
============================================================================================*/

****************************Pre traitment*******************************

//Base to have occupation of individul
use "$data\s04_me_tgo2018.dta",clear 
	gen idh=100*grappe+menage
	ren s01q00a idi
	keep idh idi s04q29b s04q29c s04q29d s04q30b s04q30c s04q30d // occupation of the main job
	
	tempfile occupation
	save `occupation'

//Using household weights
use "$data/ehcvm_welfare_tgo2018.dta"
	ren hhid idh
	keep idh pcexp hhsize hhweight
	tempfile quanti
	save `quanti'

//Base where we have all individual of the survey 
use "$data/ehcvm_individu_tgo2018.dta", clear
	ren numind idi
	ren hhid idh
	
	merge 1:1 idh idi using `occupation', nogen
	merge m:1 idh using `quanti', nogen
	merge 1:1 idh idi using "$temp/labor_ind_TGO.dta", keepusing(li salaried_income self_employee_income)
	
	gen employee=1 if _m==3
	drop _m
	*merge m:1 idh using "$temp/MPO_hh_TGO.dta",nogen keepusing(wgt hhsize) //
	
	
	gen educ_never=1 if educ_hi==1
	replace educ_never=0 if educ_never==.
	gen hhid=idh

///drop unecesary vars	
drop zae lien mstat religion nation mal30j aff30j agemar arrmal durarr con30j hos12m couvmal moustiq handit handig alfab scol educ_scol telpor internet activ7j activ12m sectins volhor salaire emploi_sec sectins_sec csp_sec volhor_sec salaire_sec bank serviceconsult persconsult educ_hi
	

// Income check 

bysort idh: egen hlab=total(li)

// Renaming variables that we will not change their value labels 
	rename hhweight weight
	rename hhsize hsize
	clonevar idp=idi
	ren li labor_income
	ren diplome educ_hl
	ren s04q30c ind_det_main

	label variable age "Age of individual (continuous)"
	label variable hhid "Household identifier"
	label variable hsize "Household size"
	label variable weight "Weight"
	label variable labor_income "Individual wage income"
	label variable educ_hl "high level school"

*************************Gender***********************
// Male and gender variable. Although ms_reweight only needs gender
	// gender 
	gen female = (sexe == 2)

	assert female!=.
	//--->Male 
	recode female (0 = 1 "Male") (1=0 "Female") (nonmissing=.), gen(male)
	label variable male "==1 if male"
	
	//---> Gender
	recode female (0 = 1 "Male") (1=2 "Female") (nonmissing=.), gen(gender)
	label variable gender "RECODE of female =1 if male =2 if female"
	drop female male

*********************Education and Skills*******************************

// Generating calif variable from education categories
	recode educ_hl (0 =1 "Primary or less") (1 2 3 4 =2 "Middle-high school") (5 6 7 8 9 10 =3 "High school and more") , gen (calif)
	replace calif=1 if age<=3 //  Before was missing and deleting observations*/
	
// Creating skilled variable. 1 for 10+ years of education.
gen skilled=calif
gen gend_skilled=. 

local i=0
foreach g in 1 2 {
	foreach e in 1 2 3 {
	local ++i
		replace  gend_skilled=`i' if gender==`g' & calif==`e' & branch!=. // @kadidia here you had industry before. This variable had observations with missing 
	}
}

///Recode gend_skilled
recode gend_skilled (1=1 "Male-lowsk") (2 =2 "Male-midsk") (3=3 "Male-highsk") (4=4 "Fem-lowsk") (5 =5 "Fem-midsk") (6=6 "Fem-highsk") , gen (genderXskill)

//Label vars
label define gend_skilled 1 "Male-lowsk" 2 "Male-midsk" 3 "Male-highsk" 4 "Fem-lowsk" 5 "Fem-midsk" 6 "Fem-highsk" 

*******************************industry*********************************
clonevar sector_IO= ind_det_main

//Recode sectors 
recode  ind_det_main	(1 2= 1 "Agriculture, Forestry and annex") ///
						(3 = 2 "Fishery & Livestock") ///
						(15 = 3 "Manufacture of food products") ///
						(18 = 4 "Manufacture of clothes") ///
						(20 28 36 = 5 "Woodworking, metalwork and Other manufacturing") ///
						(45 50 = 6 "Construction and repair" ) ///
						(51 52 = 7 "Business") ////
						(55 60 65 = 8 "Hotel, Transport and financial services" ) ///
						(75 80 85 = 9 "Education, Health and public administration") ///
						(93 = 10 "Personal services and others" ) ///
						, gen(industry)
						
ta industry	if employee==1, mi // @kadidia there is still people with missng industry here

// This use a higher label to correct 
recode branch 			(1=1) (2=2) (3 4 =5) (5=6) (6= 7) (7 8=8) (9=9) (10 11=10), gen (aux_branch)
replace industry=aux_branch if industry==.


********************************Spatial****************************** 
//Recode area
recode milieu (2=1 "rural") (1=2 "urban") (nonmissing=.), gen(urb)
drop milieu

//Create quintiles by area
quantiles  pcexp [aw=weight] if urb==2 ,nq(5) keeptog (idh) gen (quanturb)
quantiles  pcexp [aw=weight] if urb==1 ,nq(5) keeptog (idh) gen (quantrural)

************************************************************************

ren sousregion sousregion_initial
clonevar prefecture= sousregion_initial

replace prefecture=100 if prefecture==601
replace prefecture=101 if (prefecture==602|prefecture==603|prefecture==604|prefecture==605|prefecture==606)
 
recode prefecture (100=100 "Agoè-Nyivé") (101=101 "golfe") (102=102 "lacs") (103=103 "BAS-MONO") (104=104 "vo") (105=105 "yoto") (106=106 "zio") (107=107 "ave") (201=201 "ogou") (202=202 "anie") (203=203 "EST-MONO") (204=204 "akebou") (205=205 "wawa") (206=206 "amou") (207=207 "danyi") (208=208 "kpele") (209=209 "kloto") (210=210 "agou") (211=211 "haho") (212=212 "MOYEN-MONO") (301=301 "tchaoudjo") (302=302 "tchamba") (303=303 "sotouboua") (304=304 "blitta") (305=305 "Sous Prefecture de MO") (401=401 "kozah") (402=402 "binah") (403=403 "doufelgou") (404=404 "keran") (405=405 "dankpen") (406=406 "bassar") (407=407 "assoli") (501=501 "tone") (502=502 "cinkasse") (503=503 "kpendjal") (504=504 "oti") (505=505 "tandjoare"), gen(sousregion)

drop prefecture

//Label vars 
label var employee "Have a job" 
label var educ_never "Never go to school"
label var gend_skilled "GenreXskills"
label var skilled "Skills"

save "$temp/02 Load groups.dta", replace