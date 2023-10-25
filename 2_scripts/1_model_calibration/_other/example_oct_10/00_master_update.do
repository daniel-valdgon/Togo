


* 0.a Prepare income data consistent with consumption 
You have for each workers (self employed + wage employee) the income and sectors such that consumption - transfers to other hhs  = income + nonlabor 


* 0.b Prepare groups 
	*--> sectors (agrupations of similar sectors such that you prepeat the same split for martin)
	*--> urban/rural <-> quintiles 
	*--> Skills 
	*--> gender
	
* 1. Create cross walk and add it to hhs


*2  Factor income 


***Sheet (Factor payment)
gen ebe_factor=1.6
gen capital factor=0.4

gen self_factor=self_employed_income/mixed_income

define mixed_income=self_employed_income * ebe_factor
gen capital_land=self_employed_income * (1-self_factor)

egen total_lab=rowtotal(wages mixed_income)


*-----------------
collapse (sum) total_lab [iw=weights], by(Skills sector)

*reshape the results and export  the figure of this into C13-AN15 (This is new sector(agragated sector))
putexcel ...... 
 
collapse (sum) total_lab [iw=weights], by(SkillsXgender sector)

putexcel ......
 
*reshape the results and export  the figure of this into  C23-AN28 (This is new sector(agragated sector))
*Do-file that loads the sector variable for 
*Same thing has been done for capital (just for exempl)

*********Sheet factor income
gen xtile quantruralwage=wage, by(rural) nq(5)
gen xtile quantruralwage=wage, by(urban) nq(5)

*****and make the same thing as above