/*============================================================================================
Project:   		CCDR Togo
Author:    		Kolohotia Kadidia Kone
Creation Date:  October 2023
Output: 		Preparing groups
============================================================================================*/

/*---------------------------------------------------------------------------
						Worker level dataset
*---------------------------------------------------------------------------*/

// Occupation of individul
use "$data\s04_me_tgo2018.dta",clear 
	gen idh=100*grappe+menage
	ren s01q00a idi
	keep idh idi s04q29b s04q29c s04q29d s04q51b s04q51c  s04q30b s04q30c s04q30d // occupation of the main job
	
	label var s04q29b "Occ main job, main group (Q: s04q29b)"
	label var s04q29c "Occ main job, subgroup 	(Q: s04q29c)"
	label var s04q51b "Occ sec job, main group	(Q: s04q51b)"
	label var s04q51c "Occ sec job, subgroup 	(Q: s04q51c)"
	
	
tempfile occupation
save `occupation'

// Welfare variables 
use "$data/ehcvm_welfare_tgo2018.dta"
	ren hhid idh
	keep idh pcexp hhsize hhweight
	
tempfile quanti
save `quanti'

// MPO_ind 
use "$temp\MPO_ind_${iso3}.dta", clear 
	keep  idh idi educy branch
	duplicates drop idh idi educy branch, force 

tempfile mincer
save `mincer'


// Individuals of the survey 
use "$data/ehcvm_individu_tgo2018.dta", clear
	ren numind idi
	ren hhid idh
	
	merge 1:1 idh idi using `occupation', nogen
	merge m:1 idh using `quanti', nogen
	merge 1:1 idh idi using `mincer', nogen 
	merge 1:1 idh idi using "$temp/labor_ind_TGO.dta", keepusing(li salaried_income self_employee_income)


// Drop unnecessary vars	
	drop zae lien mstat religion nation mal30j aff30j agemar arrmal durarr con30j hos12m couvmal moustiq handit handig alfab scol educ_scol telpor internet activ7j activ12m sectins volhor salaire emploi_sec sectins_sec csp_sec volhor_sec salaire_sec bank serviceconsult persconsult 
	
// Income check
	*bysort idh: egen hlab=total(li)


/*-------------------------------------------------------------------*
*--------------------- Survey ids			---------------------------
*-------------------------------------------------------------------*/
// Renaming variables that we will not change their value labels 
	
	gen hhid=idh
	rename hhweight weight
	rename hhsize hsize
	clonevar idp=idi
	drop _m
	
	
	label variable age "Age of individual (continuous)"
	label variable hhid "Household identifier"
	label variable hsize "Household size"
	label variable weight "Weight"
	

/*-------------------------------------------------------------------*
*--------------------- Socio-demographics --------------------------
*-------------------------------------------------------------------*/
gen socio_demographic=.
label var socio_demographic "*****************Job characteristics********************"

// Sex - Age. Note: ms_reweight needs sex variable define as 1 for males and 2 for females 

	recode sexe (1 = 1 "Male") (2=2 "Female") (nonmissing=.), gen(gender) // to create the labels 
	label variable gender " =1 male, =2 female"
	
	cap assert gender!=. // 2 observations with missing gender (not employed)
	assert gender!=0
	drop sexe
	
	//age is perfectly created 
	cap assert age!=. // 2 observations with missing age (not employed)
	
// Education
	
	gen educ_never=1 if educ_hi==1
	replace educ_never=0 if educ_never==.
	ren diplome educ_hl
	label variable educ_hl "high level school"

	*Diplome has several people with null education, people who cliam to even have 6 years of education, we move to a much better definition of education. 
	
	/*
	recode educ_hl (0 =1 "None") (1 2 3 4 =2 "Primary - Junior Secondary") (5 6 7 8 9 10 =3 "High school and more") , gen (skilled)
	replace skilled=1 if age<=3 //  Before was missing and deleting observations*/
	*/
		
	*previous education sent to Martin: 
	recode educ_hi (1 2=1 "None") (3 4 5 =2 "Primary complete or Jun secondary and more") ( 6 7 8 9 10 =3 "High school and more") , gen (calif)
	replace calif=1 if age<=3 //  Before was missing and deleting observations*/
	
	
// Creating skilled variable. 1 for 10+ years of education.
	gen skilled=calif
	gen genderXskill=. 
	
	local i=0
	foreach g in 1 2 {
		foreach e in 1 2 3 {
		local ++i
			replace  genderXskill=`i' if gender==`g' & skilled==`e'  // @kadidia here you had industry before. This variable had observations with missing 
		}
	}

	//Label vars
	label define genderXskill 1 "Male-lowsk" 2 "Male-midsk" 3 "Male-highsk" 4 "Fem-lowsk" 5 "Fem-midsk" 6 "Fem-highsk" 
	label values genderXskill genderXskill
	
	label var genderXskill "GenreXskills"
	label var skilled " =1 none =2 primary and jun second =3 secondary & tertiary" 
*-------------------------------------------------------------------*
*------------------ Job characteristics -----------------------------* 
*-------------------------------------------------------------------*
gen job=.
label var job "*****************Job characteristics********************"
/*Employed*/

	ren li labor_income
	label variable labor_income "Individual wage income"
	
	gen employee=1 if labor_income!=. 
	label var employee "Have a job" 

	
/* Industry */
	*s04q30c  
	*s04q30b==4
	*s04q30b==2
	
	clonevar ind_original=s04q30c
	*Notice some of s04q30c==. can be recoevered from s04q30b. Sectors that are actually important 
	// @kadidia, we have several missing values (392) that coudl initially be solve by exploiting s04q30b 
	
	replace ind_original=101 if ind_original==. & (s04q30b==4 | s04q30b==2) // adding new sector
	replace ind_original=102 if ind_original==. & (s04q30b==3) // adding new sector
	replace ind_original=103 if ind_original==. & (s04q30b==1) // adding new sector
	replace ind_original=104 if ind_original==. & (s04q30b==8) // adding new sector
	replace ind_original=105 if ind_original==. & (s04q30b==9 | s04q30b==10) // adding new sector
	replace ind_original=106 if ind_original==. & (s04q30b>=14 & s04q30b<=19) // adding new sector
	*ind_det_main
	
	//Recode sectors 
	recode  ind_original	(1 2= 1 "1-Agriculture") ///
							(3 103= 2 "2-Fishery & Livestock") ///
							(101= 3 "3-Mining, water, electricity") ///
							(15 = 4 "4-Manufacture of food products and beverage") ///
							(18 = 5 "5-Textiles,clothing,leather and travel goods and footwear ") ///
							(20 28 36 102 = 6 "6-Other manufacturing ") /// Metallurgical and foundry products
							(45 = 7 "7-Construction" ) ///
							(50 51 52 = 8 "8-Wholesale and retail trade; repair of motor vehicles") //// 52 observations for repair 
							(55 = 9 "9-Hotel and restaurants" ) ///
							(60 104= 10 "10-Transport" ) ///
							(65 75 105 = 11 "11-Financial services & Public administration" ) ///
							(80 = 12 "12-Education") ///
							(85 = 13 "13-Health") ///
							(93 106 = 14 "14-Personnal services") ///
							, gen(industry)
							
							
	ta industry	if employee==1, mi // @kadidia there is still people with missng industry here
	
	// @kadidia, I propose this way to solve for missing values (intially this was solving 400 cases but I fugure out that this problem just affect 8 observations)
	bysort branch: egen aux=mode(industry)
	replace industry=aux if industry==.
	drop aux 
	
	ta industry	if employee==1, mi // @kadidia there is still people with missng industry here (See my solution above)
	replace industry=. if employee!=1 // This was necessary to make consistent employment and industry definitions. is about half million difference where 400K is because of younger than 15 yo
	
/* Occupation */
	
	clonevar main_occ=s04q29b
	// input missing values 
	bysort branch: egen aux_occ=mode(main_occ) // s04q51b is not good source to replace missing occupation 
	replace main_occ=aux_occ if main_occ==.
	replace main_occ=. if employee!=1 // is about half million difference where 400K is because of younger than 15 yo
	
	// input missing values 
	recode main_occ ( 1 2 3 4 5 =0 "Low risk") ( 6 7 8 9 10 11 12 = 1 "High risk"), gen (heat_stress_occ)
		

*-------------------------------------------------------------------*
* ------------------------ Spatial ---------------------------------
*-------------------------------------------------------------------*
 
gen spatial=.
label var spatial "*****************Spatial********************"
//Recode area
recode milieu (2=1 "rural") (1=2 "urban") (nonmissing=.), gen(urb)
drop milieu

//Create quintiles by area
quantiles  pcexp [aw=weight] if urb==2 ,nq(5) keeptog (idh) gen (quanturb)
quantiles  pcexp [aw=weight] if urb==1 ,nq(5) keeptog (idh) gen (quantrural)

ren sousregion sousregion_initial

recode sousregion_initial (601=100 "agoè-nyivé") (602 603 604 605 606=101 "golfe") (102=102 "lacs") (103=103 "bas-mono") (104=104 "vo") (105=105 "yoto") (106=106 "zio") (107=107 "ave") ///
(201=201 "ogou") (202=202 "anie") (203=203 "est-mono") (204=204 "akebou") (205=205 "wawa") (206=206 "amou") (207=207 "danyi") (208=208 "kpele") (209=209 "kloto") (210=210 "agou") (211=211 "haho") (212=212 "moyen-mono") ///
(301=301 "tchaoudjo") (302=302 "tchamba") (303=303 "sotouboua") (304=304 "blitta") (305=305 "Mô") ///
(401=401 "kozah") (402=402 "binah") (403=403 "doufelgou") (404=404 "keran") (405=405 "dankpen") (406=406 "bassar") (407=407 "assoli") ///
(501=501 "tone") (502=502 "cinkasse") (503=503 "kpendjal") (504=504 "oti") (505=505 "tandjoare"), gen(sousregion)


*-------------------------------------------------------------------*
* ----------- Consumption based income-------------------------------
*-------------------------------------------------------------------*

gen cons_inc=.
label var cons_inc "************** consumption based income *****************"


*-------------------------------------------------------------------*
* ------------------------ Spatial ---------------------------------
*-------------------------------------------------------------------*

keep  country year vague idh  menage idi weight resid ///
		socio_demographic gender age genderXskill skilled ///
		job employee branch industry ind_original csp heat_stress_occ ///
		spatial  urb grappe region sousregion_initial sousregion quanturb quantrural ///
		cons_inc pcexp labor_income
	
order country year vague idh  menage idi weight resid ///
		socio_demographic gender age genderXskill skilled ///
		job employee branch industry ind_original csp heat_stress_occ ///
		spatial  urb grappe region sousregion_initial sousregion quanturb quantrural ///
		cons_inc pcexp labor_income


		
		
save "$temp/02 Load groups.dta", replace