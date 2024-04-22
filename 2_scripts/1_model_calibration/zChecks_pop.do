/*============================================================================================
Project:   CCDR Togo
Author:    Kolohotia Kadidia Kone/konkadidia19@gmail.com
Creation Date: November 2023
Output: Population treatment
============================================================================================*/


use "$data/ehcvm_individu_tgo2018.dta",clear


******************Code pop********************
ren sousregion sousregion_initial
clonevar prefecture= sousregion_initial

replace prefecture=100 if prefecture==601
replace prefecture=101 if (prefecture==602|prefecture==603|prefecture==604|prefecture==605|prefecture==606)
 
recode prefecture (100=100 "Agoè-Nyivé") (101=101 "golfe") (102=102 "lacs") (103=103 "BAS-MONO") (104=104 "vo") (105=105 "yoto") (106=106 "zio") (107=107 "ave") (201=201 "ogou") (202=202 "anie") (203=203 "EST-MONO") (204=204 "akebou") (205=205 "wawa") (206=206 "amou") (207=207 "danyi") (208=208 "kpele") (209=209 "kloto") (210=210 "agou") (211=211 "haho") (212=212 "MOYEN-MONO") (301=301 "tchaoudjo") (302=302 "tchamba") (303=303 "sotouboua") (304=304 "blitta") (305=305 "Sous Prefecture de MO") (401=401 "kozah") (402=402 "binah") (403=403 "doufelgou") (404=404 "keran") (405=405 "dankpen") (406=406 "bassar") (407=407 "assoli") (501=501 "tone") (502=502 "cinkasse") (503=503 "kpendjal") (504=504 "oti") (505=505 "tandjoare"), gen(tgo_prefecture)

ren tgo_prefecture sousregion

collapse (sum) hhweight , by(sousregion)
ren hhweight pop_survey

tempfile pop
save `pop'

*************************************************

	import excel "$results\SAMshares.xlsx", sheet("Pop_stat_brute") firstrow clear
	gen pop_2018=0.22*Population_2010 + 0.78*Population_2022
	egen tot_pop_2018=total(pop_2018)
	merge 1:1 sousregion using `pop', nogen
	egen tot_pop_survey=total(pop_survey)
	
	*****Proportion
	
	gen percent_2018=(pop_2018/tot_pop_2018)*100
	sort percent_2018
	
	gen percent_survey=(pop_survey/tot_pop_survey)*100
	sort percent_survey
	
	//write in the excel sheetsheet

	export excel "$results/SAMshares.xlsx", sheetreplace firstrow(variables) sheet("Pop_stat_ST") 
	
	