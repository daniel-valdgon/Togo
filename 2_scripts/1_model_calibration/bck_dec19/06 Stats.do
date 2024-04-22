/*============================================================================================
Project:   CCDR Togo
Author:    Kolohotia Kadidia Kone/konkadidia19@gmail.com
Creation Date: November 2023
Output: Statistics
============================================================================================*/

use "$temp/02 Load groups.dta", clear

keep idi idh genderXskill skilled industry weight quanturb quantrural ind_det_main salaried_income self_employee_income employee gend_skilled urb sousregion region

keep if self_employee_income!=. | salaried_income!=.

egen tot_inc = rowtotal(salaried_income self_employee_income)
gen worker=employee
recode skilled (1=1 "Low") (2=2 "Middle") (3=3 "High"), gen(Skills)

***********

preserve

gen Skills_definition= "Education" 
collapse (sum) tot_inc worker [iw=weight], by(industry Skills Skills_definition)
drop if industry==.
replace  worker= round(worker)

tempfile educ_stat
save `educ_stat'

restore

*************
preserve

gen Skills_definition="Education_sex"

collapse (sum) tot_inc worker [iw=weight], by(industry genderXskill Skills_definition)
drop if industry==.
replace  worker= round(worker)

tempfile educsex_stat
save `educsex_stat'

restore

*************
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

*******Compilation

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


///ADMIN 2

preserve

keep sousregion
duplicates drop

tempfile sousr
save `sousr'

restore

preserve
keep industry
duplicates drop
cross using `sousr'

gen num =_n

tempfile fin
save `fin'

restore

preserve

use `fin', clear

merge 1:m industry sousregion using "$temp/02 Load groups.dta", keepus(self_employee_income salaried_income weight employee) nogen

replace self_employee_income=0 if self_employee_income==.
replace salaried_income=0 if salaried_income==.
replace employee=0 if employee==.
replace weight=1 if weight==.

egen tot_inc=rowtotal(salaried_income self_employee_income)
gen worker=employee
 
collapse (sum) tot_inc worker [iw=weight], by(industry sousregion) cw
drop if industry==.
replace  worker= round(worker)


//write in the excel sheetsheet

export excel "$results/SAMshares.xlsx", sheetreplace firstrow(variables) sheet("Stat_Admin2Xsector") 
 
restore

