/*******************************************************************************
 Master .do file #1
 Description : This program prepares household survey data for better nowcasting/forecasting of household welfare
 and thus various poverty and equity measures.  Only needs to be run once on the household survey data.
 Calls two other do files:
   01-1 standardize variables: creates standard household and individual datasets, specific to survey
   01-2 mincer equation: should work for any country as long as the standard datasets can be constructed
 Authors: Mohamed Coulibaly/Sidi Mohamed Sawadogo, revised by Liz Foster
 Email: ssawadogo2@worldbank.org/mcoulibaly2@worldbank.org/efoster1@worldbank.org
 Last update : 7 July 2023
 
 country : Togo
 Data: EHCVM 2018/19
********************************************************************************/

/* ---- 3. Run do files ----------------------------------------------------- */

cap which coefplot
if _rc ssc install coefplot

cap log close
log using "$temp\prepare data ${iso3}.log", replace text 	

do "$do\01-1 standardize variables EHCVM1.do" 
do "$do\01-1 zchecks.do" 
do "$do\01-2 mincer equation.do"

log close