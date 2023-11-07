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

/* ---- Folder paths ---------------------------------- */
global do   "${toolA}/2_scripts/1_model_calibration" 

global iso3 "TGO"
global data "${toolA}/1_data/ehcvm_2018/raw"
global temp "${toolA}/1_data/temp"
global results "${toolA}/3_results/SAMshares.xlsx"



/* ---- Ado files and programs ---------------------------------- */
*New programs to be added in the ado_folder or installed if required several ado-files 

*ado
foreach v in winsor2 coefplot {
	cap which `v'
	if _rc ssc install `v'
}

/* ---- Country-specific parameters ---------------------------------- */

*@kadidia it would be easy to have all glogals in the same do-file rather than repited across do-files
*	global data "C:\Users\KADIDIA KONE\Documents\CEQ_to focus on\CCDR Togo\CCDR TOGO\data\"



global icp 246.59648
global cpi 0.9970552



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

cap log close
log using "$temp\runall${iso3}.log", replace text 	

/*------------ 1 Compute a consumption based income --------------------

  This first set of do-files use the methodology implemented by Hernani Limarino 2023 and subsequently implemented by 
  Mohamed Coulibaly & Sidi Mohamed Sawadogo & Liz Foster in the MPO projections

   Inputs: 
	
   Outputs: 
   MPO_hh_TGO.dta
   labor_ind_TGO.dta

*/
	do "$do\01-1 standardize variables EHCVM1.do" // 01-1 standardize variables: creates standard household and individual datasets, specific to survey
	do "$do\01-1 zchecks.do" 
	do "$do\01-2 mincer equation.do" //  01-2 mincer equation: should work for any country as long as the standard datasets can be constructed
	
	
/*---------- 2 	Relabel groups ---------------
	
   Inputs: 
	
   Outputs: 

*/
	do "$do\02 Load groups.do" 
	do "$do\03 Factor income.do"
	do "$do\04 Transfers.do"
	do "$do\05 Consumption.do"
	

log close 	
	
	