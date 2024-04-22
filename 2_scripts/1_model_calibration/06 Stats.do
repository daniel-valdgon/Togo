/*============================================================================================
Project:   CCDR Togo
Author:    Kolohotia Kadidia Kone/konkadidia19@gmail.com
Creation Date: November 2023
Output: Statistics
============================================================================================*/

use "$temp/02 Load groups.dta", clear

keep idi idh employee genderXskill skilled industry weight quanturb quantrural  employee  urb sousregion region labor_income heat_stress_occ

clonevar tot_inc = labor_income 
gen worker=employee
recode skilled (1=1 "Low") (2=2 "Middle") (3=3 "High"), gen(Skills)

/*-------------------------------------
		Industry X Skills 
*--------------------------------------*/

preserve
	
	gen Skills_definition= "Education" 
	collapse (sum) tot_inc worker [iw=weight], by(industry Skills Skills_definition)
	drop if industry==.
	replace  worker= round(worker)
	
	tempfile educ_stat
	save `educ_stat'
	
restore

/*-------------------------------------
		Industry X Gender X Skills 
*--------------------------------------*/

preserve

	gen Skills_definition="Education_sex"
	
	collapse (sum) tot_inc worker [iw=weight], by(industry genderXskill Skills_definition)
	drop if industry==.
	replace  worker= round(worker)
	
	tempfile educsex_stat
	save `educsex_stat'
	
restore

/*-------------------------------------
		Area X Skills 
*--------------------------------------*/

preserve

	//Create areaXskills
	
	gen area_skilled=.
	
	local i=0
	foreach g in 1 2 {
		foreach e in 1 2 3 {
		local ++i
		replace  area_skilled=`i' if urb==`g' & Skills==`e' & industry!=.
		}
	}
	
	///Recode area_skills
	recode area_skilled (1=1 "Rural-lowsk") (2 =2 "Rural-midsk") (3=3 "Rural-highsk") (4= 4 "Urban-lowsk") (5 =5 "Urban-midsk") (6=6 "Urban-highsk") , gen (areaXskill)
	
	
	///
	
	gen Skills_definition="Education_area"
	
	collapse (sum) tot_inc worker [iw=weight], by(industry areaXskill Skills_definition)
	drop if industry==.
	replace  worker= round(worker)
	
	tempfile educarea_stat
	save `educarea_stat'
	
restore

/*-------------------------------------
		Compilation
*--------------------------------------*/

preserve

	use `educ_stat', clear
	append using `educsex_stat'
	append using `educarea_stat'
	
	///Recode
	gen y=0
	replace y=1 if Skills==1
	replace y=2 if Skills==2
	replace y=3 if Skills==3
	
	replace y=4 if genderXskill==1
	replace y=5 if genderXskill==2
	replace y=6 if genderXskill==3
	replace y=7 if genderXskill==4
	replace y=8 if genderXskill==5
	replace y=9 if genderXskill==6
	
	replace y=10 if areaXskill==1
	replace y=11 if areaXskill==2
	replace y=12 if areaXskill==3
	replace y=13 if areaXskill==4
	replace y=14 if areaXskill==5
	replace y=15 if areaXskill==6
	
	recode y (1=1 "Low") (2=2 "Middle") (3=3 "High") (4=4 "Male-lowsk") (5=5 "Male-midsk") (6=6 "Male-highsk") (7=7 "Fem-lowsk") (8=8 "Fem-midsk") (9=9 "Fem-highsk") (10=10 "Rural-lowsk") (11=11 "Rural-midsk") (12=12 "Rural-highsk") (13= 13 "Urban-lowsk") (14 =14 "Urban-midsk") (15=15 "Urban-highsk"), gen(Skills_category)
	
	drop Skills genderXskill areaXskill y
	
	//write in the excel sheetsheet
	
	export excel "$results/SAMshares.xlsx", sheetreplace firstrow(variables) sheet("Stat")
	
restore

/*-------------------------------------
		Spatial 
*--------------------------------------*/
	
	// Loading population to make a better national weighted average 
	preserve 
		import excel using "${toolA}/1_data/population_2018_2022.xlsx", sheet(Pop_stat_brute) clear first
		gen pop_reg_18=((Population_2022/Population_2010)^(8/12))*Population_2010
		keep pop_reg_18 sousregion Name
		tempfile pop_data
		save `pop_data', replace 
	restore 
	
	// Creating all manufacturing region combinations
	replace employee=0 if employee!=1 
	replace heat_stress_occ=2 if employee!=1 
	replace  industry=100 if industry==. & employee!=1 // this industry correspond to not employed people, to facilitate calculation of the employment rate at aggregate level 
		
	fillin sousregion industry
		
	foreach v in employee weight tot_inc {
		replace `v'=0 if _fillin==1
	}
		
	gen pop=_fillin==0
	
	collapse (sum) tot_inc employee pop  [iw=weight], by(heat_stress_occ industry sousregion)  fast // @kadidia using the option cw (case deletion) could be dangerous because in this example it delete when industry was 100 (no industry category with positive values for population)
	// drop if industry==. @kadidia this was a mistake, usually you solve the missing issues rather than drop them 
	
	bysort sousregion: egen pop_reg=total(pop)
	bysort sousregion: egen emp_reg=total(employee)
	egen emp_nat=total(employee)
	
	gen emp_rate=emp_reg/pop_reg
	
	
	drop if industry==100 // it was only for the employment rate 
		
	merge m:1 sousregion using `pop_data', nogen 
	
	gen emp_weight_occu_prefecture=employee/emp_reg
	bysort sousregion: gen n=_n
	gen emp_proj_reg=emp_rate*pop_reg_18 if n==1
	egen emp_proj_nat=total(emp_proj_reg)
	bysort sousregion: ereplace emp_proj_reg=max(emp_proj_reg)
	gen emp_weight_prefecture_nat_adj=emp_proj_reg/emp_proj_nat
	gen emp_weight_prefecture_nat_unad=emp_reg/emp_nat
	
	gen code_prefecture=sousregion
	format %20.6f tot_inc
	
	keep  Name code_prefecture emp_weight_prefecture_nat_unad emp_weight_prefecture_nat_adj emp_weight_occu_prefecture tot_inc employee pop_reg pop_reg_18 industry heat_stress_occ
	
	order code_prefecture Name industry heat_stress_occ emp_weight_prefecture_nat_unad emp_weight_prefecture_nat_adj emp_weight_occu_prefecture tot_inc employee pop_reg pop_reg_18
	
	
	//write in the excel sheetsheet
	
	export excel "$results/IEc.xlsx", sheetreplace firstrow(variables) sheet("Stat_Admin2Xsector") 
