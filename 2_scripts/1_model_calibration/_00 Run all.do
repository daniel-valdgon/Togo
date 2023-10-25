/*******************************************************************************
***Run all dofiles
 Made by Kadidia Kone/konkadidia19@gmail.com
 country : Togo
 Data: EHCVM 2018/19
************************************************************************/


if "`c(username)'"=="wb419055"	{
	// project path 
	global toolA "C:\Users\wb419055\OneDrive - WBG\West Africa\Togo"
	
	// data path 
}

global iso3 "TGO"
global data "${toolA}/1_data/ehcvm_2018"
global temp "${toolA}/1_data/temp"







/* ---- 1. Set country-specific parameters ---------------------------------- */

*@kadidia if wuold be easy to have all glogals in the same do-file rather than repited across do-files
*	global data "C:\Users\KADIDIA KONE\Documents\CEQ_to focus on\CCDR Togo\CCDR TOGO\data\"



global icp 246.59648
global cpi 0.9970552



*@why kadidia, if this folders did not exist in your original folder
*
*global logs "${toolA}\LOG"
*global dat "${toolA}\DAT"
*global data "${toolA}\data"

/*
global toolA "C:\Users\KADIDIA KONE\Documents\CEQ_to focus on\CCDR Togo\CCDR TOGO"
global do   "${toolA}\DO" 
global temp "${toolA}\TEMP"
global logs "${toolA}\LOG"
global dat "${toolA}\DAT"
global data "${toolA}\data"

*/

global do   "${toolA}/2_scripts/1_model_calibration" 

cap log close
log using "$temp\runall${iso3}.log", replace text 	

	do "$do\01 prepare data TGO.do" 
	do "$do\02 Load groups.do" 
	do "$do\03 Factor income.do"
	
	
	
	